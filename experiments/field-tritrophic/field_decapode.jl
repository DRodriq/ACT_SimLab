# Phase 1 (A) — express the spatial grass↔prey↔predator system as a Decapode (the DSL), then verify
# it reproduces the closed-form tri-trophic Rosenzweig–MacArthur equilibrium in the uniform limit.
#
# All three are Form0 densities on the mesh (per the Gray–Scott idiom: nonlinear form products use
# broadcast `.*`/`.-`/`./`; constants scale with `*`):
#   ∂ₜG = Dg·ΔG + r·G(1−G/K) − a·G·P
#   ∂ₜP = Dp·ΔP + a·G·P − m_p·P − b·P·Q
#   ∂ₜQ = Dq·ΔQ + b·P·Q − m_q·Q
# Closed-form well-mixed equilibrium:  P* = m_q/b,  G* = K(1 − a·m_q/(b·r)),  Q* = (a·G* − m_p)/b.
#
# Run from sim_lab/ :  julia --project=. scripts/field_decapode.jl

using Catlab, CombinatorialSpaces, DiagrammaticEquations, Decapodes
using ComponentArrays, DifferentialEquations, LinearAlgebra

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

# 2-D triangulated grid — Decapodes' gensim'd Δ is built/tested for 2-D (its 1-D dual-derivative
# codegen is incomplete). Uniform IC ⇒ diffusion inert ⇒ the equilibrium check is mesh-agnostic.
function grid_mesh(maxx::Float64, maxy::Float64, dx::Float64, dy::Float64)
    s = triangulated_grid(maxx, maxy, dx, dy, Point3D)
    sd = EmbeddedDeltaDualComplex2D{Bool, Float64, Point2D}(s)
    subdivide_duals!(sd, Circumcenter())
    sd
end

sd  = grid_mesh(20.0, 20.0, 1.0, 1.0)
sim = eval(gensim(SpatialRM))
generate(sd, sym; hodge = GeometricHodge()) = error("no custom operator $sym")
fₘ  = sim(sd, generate, DiagonalHodge())
println("decapode compiled; sim built")

NV = nv(sd)
u0 = ComponentArray(G = fill(1.0, NV), P = fill(1.0, NV), Q = fill(1.0, NV))
pr = (r = 1.0, K = 5.0, a = 0.5, mp = 0.5, b = 0.5, mq = 0.5, Dg = 0.1, Dp = 0.1, Dq = 0.1)
sol = solve(ODEProblem(fₘ, u0, (0.0, 300.0), pr), Tsit5(); saveat = 300.0, abstol = 1e-9, reltol = 1e-9)

Pstar = pr.mq / pr.b
Gstar = pr.K * (1 - pr.a * pr.mq / (pr.b * pr.r))
Qstar = (pr.a * Gstar - pr.mp) / pr.b
ue = sol.u[end]
gm, pm, qm = sum(ue.G)/NV, sum(ue.P)/NV, sum(ue.Q)/NV
println("analytic  G*=", Gstar, "  P*=", Pstar, "  Q*=", Qstar)
println("numeric   G =", round(gm, digits=4), "  P =", round(pm, digits=4), "  Q =", round(qm, digits=4))
println("rel.err   G=", round(abs(gm-Gstar)/Gstar, digits=5),
        "  P=", round(abs(pm-Pstar)/Pstar, digits=5),
        "  Q=", round(abs(qm-Qstar)/Qstar, digits=5))
