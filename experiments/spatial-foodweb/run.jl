# Experiment: spatial-foodweb — a harness Scenario distributed over a grid (the spatial layer)
# Question: does the currency harness reproduce a spatial invasion wave when a Scenario is
#           stratified over an N×N grid with mobile (diffusing) consumers — conserving globally?
# Run: julia --project=. experiments/spatial-foodweb/run.jl   → outputs/{spatial,composition}.png

using SimLab, CairoMakie
include(joinpath(@__DIR__, "..", "..", "tools", "composition.jl"))

B = Currency(:biomass, false)
scn = Scenario([B],
    [Pool(:grass,    :producer,[1.0],0.0,0.00,0.05,[1.0],0.0),   # logistic (K=20), immobile
     Pool(:prey,     :consumer,[1.0],0.0,0.10,0.0, [0.0],0.0),
     Pool(:predator, :consumer,[1.0],0.0,0.05,0.0, [0.0],0.0),
     Pool(:detritus, :dead,    [1.0],0.0,0.0, 0.0, [0.0],0.0)],
    [Feed(:grass,:prey,0.3,1.0,0.2), Feed(:prey,:predator,0.3,1.0,0.2)],
    :detritus, Dict(:grass=>[20.0],:prey=>[0.0],:predator=>[0.0],:detritus=>[0.0]), [0.0])

N = 20
seedfn = (u0,L) -> begin                                          # seed a central 3×3 patch
    c = N÷2
    for r in c-1:c+1, cc in c-1:c+1
        t = (r-1)*N + cc
        u0[L.Ai(t,L.pidx[:prey],1)]     = 0.8
        u0[L.Ai(t,L.pidx[:predator],1)] = 0.4
    end
end
sol,L = run_spatial(scn, N, Dict(:prey=>0.4, :predator=>0.4); T=40.0, seed=seedfn)   # mobile consumers diffuse
_,od = drifts_spatial(sol,L)
@assert od[1] < 1e-6                                              # GATE: biomass conserved across the whole grid
println("spatial-foodweb: ",N,"×",N," grid (",L.T," tiles), open-biomass drift = ",round(od[1];sigdigits=2))

times = [8.0, 20.0, 40.0]; idxs = [argmin(abs.(sol.t .- tt)) for tt in times]
out = joinpath(@__DIR__,"outputs"); mkpath(out)
fig = Figure(size=(900, 840))
for (ri,(nm,cmap)) in enumerate([(:grass,:viridis),(:prey,:magma),(:predator,:plasma)])
    cr = (0.0, maximum(maximum(role_field(sol.u[i],L,nm)) for i in idxs)+1e-9)
    for (ci,ix) in enumerate(idxs)
        ax = CairoMakie.Axis(fig[ri,ci], aspect=1, yreversed=true,
            title = ri==1 ? "t = $(times[ci])" : "", ylabel = ci==1 ? string(nm) : "")
        hidedecorations!(ax; label=false)
        heatmap!(ax, role_field(sol.u[ix],L,nm), colormap=cmap, colorrange=cr)
    end
end
save(joinpath(out,"spatial.png"),fig); println("saved -> ",joinpath(out,"spatial.png"))
composition_graph(scn, joinpath(out,"composition.png"); title="grass → prey → predator")
println("saved -> ",joinpath(out,"composition.png"))
