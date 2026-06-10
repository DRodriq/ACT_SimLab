# Experiment: grass-prey-predator — Rosenzweig–MacArthur coexistence (carrying capacity rescues the predator)
# Question: does logistic grass (a carrying capacity) rescue the predator from the tri-trophic collapse
#           that exponential grass produces?
# Run: julia --project=. experiments/grass-prey-predator/run.jl   → outputs/{dynamics,composition}.png

using SimLab, CairoMakie
include(joinpath(@__DIR__, "..", "..", "tools", "composition.jl"))

B = Currency(:biomass, false)
scn(crowd) = Scenario([B],
    [Pool(:grass,    :producer,[1.0],0.0,0.00,crowd,[1.0],0.0),   # crowd>0 = logistic; crowd=0 = exponential
     Pool(:prey,     :consumer,[1.0],0.0,0.10,0.0,[0.0],0.0),
     Pool(:predator, :consumer,[1.0],0.0,0.05,0.0,[0.0],0.0),
     Pool(:detritus, :dead,    [1.0],0.0,0.0, 0.0,[0.0],0.0)],
    [Feed(:grass,:prey,0.2,1.0,0.12), Feed(:prey,:predator,0.3,1.0,0.15)],
    :detritus, Dict(:grass=>[3.0],:prey=>[1.0],:predator=>[0.5],:detritus=>[0.0]), [0.0])

solL,L = run_scenario(scn(0.02); T=300.0); rL = classify(solL,L,[:grass,:prey,:predator])   # logistic
solE,_ = run_scenario(scn(0.0);  T=300.0); rE = classify(solE,L,[:grass,:prey,:predator])   # exponential
@assert Set(rL.surviving)==Set([:grass,:prey,:predator]) && rL.conserved   # GATE: carrying capacity → coexistence
println("grass-prey-predator:  logistic → stable coexistence (",rL.regime,", ",join(rL.surviving,"/"),
        ")   |   exponential → unbounded: grass+predator run away, prey crashes")

out = joinpath(@__DIR__,"outputs"); mkpath(out)
fig = Figure(size=(980,380))
for (ci,(label,sol)) in enumerate([("logistic grass (RM): stable coexistence",solL),
                                    ("exponential grass: no carrying capacity → runaway",solE)])
    ax=Axis(fig[1,ci],title=label,xlabel="t",ylabel="biomass",yscale=log10)
    for (nm,c) in ((:grass,:seagreen),(:prey,:slateblue),(:predator,:firebrick))
        lines!(ax,sol.t,max.([ssize(u,L,L.pidx[nm]) for u in sol.u],1e-6),color=c,label=string(nm))
    end
    axislegend(ax;position=:rb,labelsize=9)
end
save(joinpath(out,"dynamics.png"),fig); println("saved -> ",joinpath(out,"dynamics.png"))

composition_graph(scn(0.02), joinpath(out,"composition.png"); title="grass → prey → predator")
println("saved -> ",joinpath(out,"composition.png"))
