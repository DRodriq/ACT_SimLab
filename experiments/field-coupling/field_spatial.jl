# Phase 1 — spatial demonstration: a traveling grazing wave from the validated field↔population
# coupling. Uniform grass at carrying capacity + a localized prey pulse → prey invade outward,
# grazing grass down to g* = m_p/a in the wake (which then regrows logistically). The first
# genuinely spatial result; exercises diffusion + the coupling together.
#
# Run from sim_lab/ :  julia --project=. scripts/field_spatial.jl

using CombinatorialSpaces, DifferentialEquations, LinearAlgebra, CairoMakie

function line_mesh(N::Int, L::Float64)
    s = EmbeddedDeltaSet1D{Bool, Point2D}()
    h = L / (N - 1)
    add_vertices!(s, N, point = [Point2D((i - 1) * h, 0.0) for i in 1:N])
    add_edges!(s, 1:(N-1), 2:N)
    sd = EmbeddedDeltaDualComplex1D{Bool, Float64, Point2D}(s)
    subdivide_duals!(sd, Circumcenter())
    sd
end

const N, L = 401, 100.0
const sd = line_mesh(N, L)
const L0 = Δ(0, sd)
xs = collect(range(0, L; length = N))

p = (r = 1.0, K = 5.0, a = 0.5, mp = 1.0, Dg = 0.1, Dp = 1.0)   # a·K=2.5 > m_p=1 ⇒ prey invade
gstar = p.mp / p.a

function rhs!(du, u, par, _t)
    (; r, K, a, mp, Dg, Dp) = par
    g  = @view u[1:N];   q  = @view u[N+1:2N]
    dg = @view du[1:N];  dq = @view du[N+1:2N]
    dg .= r .* g .* (1 .- g ./ K) .- a .* g .* q .+ Dg .* (L0 * g)
    dq .= a .* g .* q .- mp .* q              .+ Dp .* (L0 * q)
end

g0 = fill(p.K, N)                                   # grass at carrying capacity everywhere
q0 = 1.0 .* exp.(-((xs .- L/2) .^ 2) ./ (2 * 2.0^2)) # localized prey pulse at center
T  = 18.0
sol = solve(ODEProblem(rhs!, vcat(g0, q0), (0.0, T), p), TRBDF2(); saveat = 0.25, abstol = 1e-8, reltol = 1e-8)

ts = sol.t
G = reduce(hcat, (u[1:N]      for u in sol.u))       # N × ntime
P = reduce(hcat, (u[N+1:2N]   for u in sol.u))
println("grass wake min = ", round(minimum(G), digits = 3), "  (expect ≈ g* = ", gstar, ")")
println("prey max       = ", round(maximum(P), digits = 3))

fig = Figure(size = (1000, 420))
ax1 = Axis(fig[1, 1], xlabel = "space x", ylabel = "time t", title = "grass density g(x,t)")
hm1 = heatmap!(ax1, xs, ts, G, colormap = :viridis); Colorbar(fig[1, 2], hm1)
ax2 = Axis(fig[1, 3], xlabel = "space x", ylabel = "time t", title = "prey density p(x,t)")
hm2 = heatmap!(ax2, xs, ts, P, colormap = :magma); Colorbar(fig[1, 4], hm2)
out = joinpath(@__DIR__, "field_spatial.png"); save(out, fig)
println("saved -> ", out)
