# Experiment: trophic-chain — conserved biomass chain grass→sheep→wolf with Lindeman efficiency
# Question: what standing biomass emerges from a conserved chain, and does it pyramid?
# Run: julia --project=. experiments/trophic-chain/run.jl   → outputs/chain.png

using SimLab, CairoMakie

B = Currency(:biomass, false)
scn = Scenario([B],
    [Pool(:grass,:producer,[1.0],0.0,0.0,0.02,[1.0],0.0),   # logistic producer (carrying capacity K=50)
     Pool(:sheep,:consumer,[1.0],0.0,0.10,0.0,[0.0],0.0),
     Pool(:wolf, :consumer,[1.0],0.0,0.05,0.0,[0.0],0.0),
     Pool(:detritus,:dead, [1.0],0.0,0.0,0.0,[0.0],0.0)],
    [Feed(:grass,:sheep,0.2,1.0,0.1), Feed(:sheep,:wolf,0.2,1.0,0.1)],   # ε=0.1 (Lindeman) per link
    :detritus, Dict(:grass=>[5.0],:sheep=>[1.0],:wolf=>[0.3],:detritus=>[0.0]), [0.0])

sol,L = run_scenario(scn; T=400.0)
r = classify(sol,L,[:grass,:sheep,:wolf])
@assert Set(r.surviving)==Set([:grass,:sheep,:wolf]) && r.conserved   # GATE: all persist, conserved
println("trophic-chain: grass=",round(ssize_end(sol,L,:grass);digits=2),
        " sheep=",round(ssize_end(sol,L,:sheep);digits=2),
        " wolf=",round(ssize_end(sol,L,:wolf);digits=2)," (all persist, conserved)")

fig=Figure(size=(640,400))
ax=Axis(fig[1,1],title="conserved trophic chain (log biomass)",xlabel="t",ylabel="biomass",yscale=log10)
for (nm,c) in ((:grass,:seagreen),(:sheep,:slateblue),(:wolf,:firebrick))
    lines!(ax,sol.t,max.([ssize(u,L,L.pidx[nm]) for u in sol.u],1e-6),color=c,label=string(nm))
end
axislegend(ax;position=:rb)
out=joinpath(@__DIR__,"outputs"); mkpath(out); save(joinpath(out,"chain.png"),fig)
println("saved -> ",joinpath(out,"chain.png"))
