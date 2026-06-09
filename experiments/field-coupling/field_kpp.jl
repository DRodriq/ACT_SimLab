# Phase 1 — field-machinery validation (ladder steps b & c) on a 1-D DEC mesh.
#
#   ∂g/∂t = r·g·(1 − g/K)  −  D·Δ·g
#
# Δ is the CombinatorialSpaces 0-form Laplacian; empirically it carries the continuum ∇² sign
# (negative at a peak), so the diffusion term is +D·Δ. Step (b) (logistic → K) is implicit; step (c)
# is the analytic oracle: a Fisher–KPP front from a step IC travels at the asymptotic speed
# c = 2√(rD). The measured speed converges to it both under mesh refinement and (from below, per the
# Bramson ~1/t logarithmic correction) as the measurement window moves later in time.
#
# Run from sim_lab/ :  julia --project=. scripts/field_kpp.jl

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

function front_speed(N::Int; L = 40.0, r = 1.0, D = 1.0, K = 1.0, x0 = 5.0, T = 12.0)
    sd = line_mesh(N, L)
    L0 = Δ(0, sd)
    x  = collect(range(0, L; length = N))
    g0 = [xi < x0 ? K : 0.0 for xi in x]
    # out-of-place L0*g (allocates at g's eltype) keeps the stiff solver's ForwardDiff Jacobian happy.
    # CombinatorialSpaces' Δ already carries the ∇² sign (negative at a peak), so diffusion is +D·Δ.
    function rhs!(dg, g, _p, _t)
        dg .= r .* g .* (1 .- g ./ K) .+ D .* (L0 * g)
    end
    sol = solve(ODEProblem(rhs!, g0, (0.0, T)), TRBDF2(); saveat = 0.5, abstol = 1e-8, reltol = 1e-8)
    # front position = where g crosses K/2 (linear interpolation between vertices)
    function xhalf(g)
        i = findlast(v -> v >= K / 2, g)
        (i === nothing || i == N) && return NaN
        x[i] + (K / 2 - g[i]) / (g[i+1] - g[i]) * (x[i+1] - x[i])
    end
    ts = sol.t
    xh = [xhalf(u) for u in sol.u]
    m  = .!isnan.(xh) .& (ts .>= 0.4T)            # steady-propagation window
    a, b = findfirst(m), findlast(m)
    (xh[b] - xh[a]) / (ts[b] - ts[a])
end

r, D = 1.0, 1.0
c_analytic = 2 * sqrt(r * D)
println("analytic KPP front speed  2√(rD) = ", c_analytic)
for N in (201, 401, 801)
    c = front_speed(N; r = r, D = D)
    println("N=", lpad(N, 4), "   measured = ", round(c, digits = 4),
            "   rel.err = ", round(abs(c - c_analytic) / c_analytic, digits = 4))
end
