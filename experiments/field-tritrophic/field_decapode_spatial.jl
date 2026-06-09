# Phase 1 — spatial 2-D run of the tri-trophic Decapode (grass↔prey↔predator as Form0 fields).
# Grass at carrying capacity everywhere + a localized prey+predator introduction → a grazing
# invasion wave spreads outward with the predator following the prey front. First 2-D, three-species
# spatial result, run entirely on the validated Decapodes (DSL) machinery.
#
# Run from sim_lab/ :  julia --project=. scripts/field_decapode_spatial.jl

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

# 2-D triangulated grid (keep primal `s` for plotting)
const M = 40.0
s = triangulated_grid(M, M, 1.0, 1.0, Point3D)
sd = EmbeddedDeltaDualComplex2D{Bool, Float64, Point2D}(s)
subdivide_duals!(sd, Circumcenter())

sim = eval(gensim(SpatialRM))
generate(sd, sym; hodge = GeometricHodge()) = error("no custom operator $sym")
fₘ = sim(sd, generate, DiagonalHodge())
println("sim built; vertices = ", nv(sd))

# ICs: grass at K; prey+predator seeded in a central disk
ctr = Point3D(M/2, M/2, 0.0)
pulse = [norm(p - ctr) <= 3.0 ? 1.0 : 0.0 for p in s[:point]]
u0 = ComponentArray(G = fill(5.0, nv(sd)), P = 0.8 .* pulse, Q = 0.5 .* pulse)
pr = (r = 1.0, K = 5.0, a = 0.5, mp = 0.5, b = 0.5, mq = 0.5, Dg = 0.05, Dp = 0.5, Dq = 0.5)

times = [1.5, 4.5, 9.0]
sol = solve(ODEProblem(fₘ, u0, (0.0, last(times)), pr), Tsit5(); saveat = times, abstol = 1e-7, reltol = 1e-7)
println("solved; snapshot count = ", length(sol.t))
for (nm, fld) in (("grass", :G), ("prey", :P), ("predator", :Q))
    v = getproperty(sol.u[end], fld)
    println("  ", rpad(nm, 9), " final range = ", round(minimum(v); digits=3), " .. ", round(maximum(v); digits=3))
end

# 3 fields (rows) × snapshot times (cols)
fields = [(:G, "grass", :viridis), (:P, "prey", :magma), (:Q, "predator", :plasma)]
fig = Figure(size = (1000, 900))
for (ri, (fld, nm, cmap)) in enumerate(fields)
    cr = (0.0, maximum(maximum(getproperty(u, fld)) for u in sol.u))   # shared range per field
    for (ci, t) in enumerate(times)
        ax = CairoMakie.Axis(fig[ri, ci], aspect = 1, title = "$nm  t=$t")
        m = mesh!(ax, s, color = getproperty(sol.u[ci], fld), colormap = cmap, colorrange = cr)
        ci == length(times) && Colorbar(fig[ri, ci+1], m)
        hidedecorations!(ax)
    end
end
out = joinpath(@__DIR__, "field_decapode_spatial.png"); save(out, fig)
println("saved -> ", out)
