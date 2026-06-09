# Phase 1 — animated 2-D tri-trophic field sim: a grid of colored values evolving through time.
# Grass at carrying capacity + several localized prey+predator seeds → interacting grazing
# invasion waves with the predator chasing. Renders an MP4 (watch it evolve) via CairoMakie.record,
# plus one PNG frame for a quick sanity look.
#
# Run from sim_lab/ :  julia --project=. scripts/field_anim.jl

using Catlab, CombinatorialSpaces, DiagrammaticEquations, Decapodes
using ComponentArrays, DifferentialEquations, LinearAlgebra, CairoMakie

SpatialRM = @decapode begin
    (G, P, Q)::Form0
    (r, K, a, mp, b, mq, Dg, Dp, Dq)::Constant
    graze == a .* (G .* P)
    pred  == b .* (P .* Q)
    Ġ == Dg .* Δ(G) .+ r .* (G .* (1.0 .- (G ./ K))) .- graze
    Ṗ == Dp .* Δ(P) .+ graze .- mp .* P .- pred
    Q̇ == Dq .* Δ(Q) .+ pred  .- mq .* Q
    ∂ₜ(G) == Ġ
    ∂ₜ(P) == Ṗ
    ∂ₜ(Q) == Q̇
end

const M = 40.0
s = triangulated_grid(M, M, 1.0, 1.0, Point3D)
sd = EmbeddedDeltaDualComplex2D{Bool, Float64, Point2D}(s)
subdivide_duals!(sd, Circumcenter())

sim = eval(gensim(SpatialRM))
generate(sd, sym; hodge = GeometricHodge()) = error("no custom operator $sym")
fₘ = sim(sd, generate, DiagonalHodge())
println("sim built; vertices = ", nv(sd))

seeds = [(10.0, 10.0), (30.0, 31.0), (12.0, 30.0), (31.0, 12.0)]
pulse = zeros(nv(sd))
for (cx, cy) in seeds
    pulse .= max.(pulse, [norm(p - Point3D(cx, cy, 0.0)) <= 2.0 ? 1.0 : 0.0 for p in s[:point]])
end
u0 = ComponentArray(G = fill(5.0, nv(sd)), P = 0.8 .* pulse, Q = 0.4 .* pulse)
pr = (r = 1.0, K = 5.0, a = 0.5, mp = 0.5, b = 0.5, mq = 0.5, Dg = 0.05, Dp = 0.5, Dq = 0.5)

T, nframes = 24.0, 120
tsave = collect(range(0, T; length = nframes))
sol = solve(ODEProblem(fₘ, u0, (0.0, T), pr), Tsit5(); saveat = tsave, abstol = 1e-7, reltol = 1e-7)
println("solved; frames = ", length(sol.u))

maxP = maximum(maximum(u.P) for u in sol.u)
maxQ = maximum(maximum(u.Q) for u in sol.u)
panels = [(:G, "grass", :viridis, (0.0, pr.K)), (:P, "prey", :magma, (0.0, maxP)), (:Q, "predator", :plasma, (0.0, maxQ))]

idx = Observable(1)
fig = Figure(size = (1050, 420))
for (ci, (fld, nm, cmap, cr)) in enumerate(panels)
    ax = CairoMakie.Axis(fig[1, ci], aspect = 1,
        title = @lift("$nm   t = $(round(tsave[$idx], digits=1))"))
    hidedecorations!(ax)
    m = mesh!(ax, s, color = @lift(getproperty(sol.u[$idx], fld)), colormap = cmap, colorrange = cr)
    Colorbar(fig[2, ci], m, vertical = false)
end

mp4 = joinpath(@__DIR__, "field_anim.mp4")
record(fig, mp4, 1:nframes; framerate = 20) do i
    idx[] = i
end
println("saved animation -> ", mp4)

idx[] = clamp(round(Int, 0.55 * nframes), 1, nframes)   # a representative mid-run frame
png = joinpath(@__DIR__, "field_anim_frame.png"); save(png, fig)
println("saved sanity frame -> ", png)
