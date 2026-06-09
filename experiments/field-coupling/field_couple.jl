# Phase 1, step 2 — couple a grass DEC field to a prey population on the mesh, via grazing.
#
# Both grass g and prey p are DENSITIES on the 1-D mesh; totals are area-weighted with the dual-cell
# volumes A = diag(⋆₀).  Grazing rates are therefore area-free; A enters only in the mass integrals.
#
#   dg/dt = r·g·(1 − g/K) + Dg·Δg − a·g·p     (grass: logistic + diffusion − grazed)
#   dp/dt = a·g·p − m_p·p     + Dp·Δp          (prey: born by grazing − mortality + diffusion)
#
# Gates:
#   (1) mass-conjugacy — with grazing only (r=Dg=Dp=m_p=0): M = Σ Aᵢ(gᵢ+pᵢ) is conserved
#       (grass mass eaten == prey amount gained, ε=1).
#   (2) uniform → equilibrium — on a uniform field+IC, converges to  g* = m_p/a,  p* = (r/a)(1 − g*/K).
#
# Run from sim_lab/ :  julia --project=. scripts/field_couple.jl

using CombinatorialSpaces, DifferentialEquations, LinearAlgebra

function line_mesh(N::Int, L::Float64)
    s = EmbeddedDeltaSet1D{Bool, Point2D}()
    h = L / (N - 1)
    add_vertices!(s, N, point = [Point2D((i - 1) * h, 0.0) for i in 1:N])
    add_edges!(s, 1:(N-1), 2:N)
    sd = EmbeddedDeltaDualComplex1D{Bool, Float64, Point2D}(s)
    subdivide_duals!(sd, Circumcenter())
    sd
end

const N, L = 201, 20.0
const sd = line_mesh(N, L)
const L0 = Δ(0, sd)
const A  = collect(diag(⋆(0, sd)))          # dual-cell volumes (mass weights)
println("Σ Aᵢ = ", round(sum(A), digits = 4), "   (should ≈ L = ", L, ")")

function rhs!(du, u, par, _t)
    (; r, K, a, mp, Dg, Dp) = par
    g  = @view u[1:N];      q  = @view u[N+1:2N]
    dg = @view du[1:N];     dq = @view du[N+1:2N]
    dg .= r .* g .* (1 .- g ./ K) .- a .* g .* q .+ Dg .* (L0 * g)
    dq .= a .* g .* q .- mp .* q              .+ Dp .* (L0 * q)
end

mass(u) = sum(A .* @view u[1:N]) + sum(A .* @view u[N+1:2N])

# --- Gate 1: mass-conjugacy (grazing only, spatially varying IC) -----------------------------
p1 = (r = 0.0, K = 5.0, a = 0.5, mp = 0.0, Dg = 0.0, Dp = 0.0)
xs = range(0, L; length = N)
g0 = 1.0 .+ 0.5 .* sin.(2π .* xs ./ L)
q0 = 0.8 .+ 0.3 .* cos.(2π .* xs ./ L)
sol1 = solve(ODEProblem(rhs!, vcat(g0, q0), (0.0, 5.0), p1), TRBDF2();
             saveat = 1.0, abstol = 1e-10, reltol = 1e-10)
M0, M1 = mass(sol1.u[1]), mass(sol1.u[end])
println(">>> Gate 1 (mass-conjugacy, grazing only):")
println("    M(t0)=", round(M0, digits = 8), "  M(tEnd)=", round(M1, digits = 8),
        "  rel.drift=", abs(M1 - M0) / abs(M0))

# --- Gate 2: uniform reproduces the closed-form equilibrium ----------------------------------
p2 = (r = 1.0, K = 5.0, a = 0.5, mp = 1.0, Dg = 0.2, Dp = 0.1)
gstar = p2.mp / p2.a
pstar = (p2.r / p2.a) * (1 - gstar / p2.K)
sol2 = solve(ODEProblem(rhs!, vcat(fill(1.0, N), fill(0.5, N)), (0.0, 200.0), p2), TRBDF2();
             saveat = 200.0, abstol = 1e-9, reltol = 1e-9)
gend = @view sol2.u[end][1:N];  qend = @view sol2.u[end][N+1:2N]
gmean = sum(A .* gend) / sum(A);  pmean = sum(A .* qend) / sum(A)
println(">>> Gate 2 (uniform → equilibrium):")
println("    analytic  g*=", gstar, "   p*=", round(pstar, digits = 4))
println("    numeric   g =", round(gmean, digits = 4), "   p =", round(pmean, digits = 4))
println("    g rel.err=", round(abs(gmean - gstar)/gstar, digits = 5),
        "   p rel.err=", round(abs(pmean - pstar)/pstar, digits = 5),
        "   spatial spread |g|=", round(maximum(gend) - minimum(gend), sigdigits = 2))
