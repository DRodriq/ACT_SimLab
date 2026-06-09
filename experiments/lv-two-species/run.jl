# Experiment: lv-two-species — the classic Lotka–Volterra neutral cycle (the "tracer")
# Question: does the harness reproduce the textbook LV neutral predator–prey cycle?
# Run: julia --project=. experiments/lv-two-species/run.jl   → outputs/lv_cycle.png

using SimLab, CairoMakie

B = Currency(:biomass, false)
scn = Scenario([B],
    [Pool(:prey,:producer,[1.0],0.0,0.0,0.0,[1.0],0.0),   # free food → exponential birth, NO carrying capacity
     Pool(:pred,:consumer,[1.0],0.0,0.6,0.0,[0.0],0.0),   # predator mortality γ = 0.6
     Pool(:detritus,:dead,[1.0],0.0,0.0,0.0,[0.0],0.0)],
    [Feed(:prey,:pred,0.5,1.0,0.5)],                       # predation: attack a=0.5, conversion e=0.5
    :detritus, Dict(:prey=>[1.0],:pred=>[0.5],:detritus=>[0.0]), [0.0])

sol,L = run_scenario(scn; T=120.0)
r = classify(sol,L,[:prey,:pred])
@assert r.regime==:cycle && r.conserved               # GATE: neutral LV cycle, bookkeeping conserved
prey=[ssize(u,L,L.pidx[:prey]) for u in sol.u]; pred=[ssize(u,L,L.pidx[:pred]) for u in sol.u]
println("lv-two-species: regime=",r.regime,", conserved=",r.conserved)

fig=Figure(size=(940,360))
ax1=Axis(fig[1,1],title="LV neutral cycle",xlabel="t",ylabel="biomass")
lines!(ax1,sol.t,prey,color=:seagreen,label="prey"); lines!(ax1,sol.t,pred,color=:firebrick,label="predator"); axislegend(ax1)
ax2=Axis(fig[1,2],title="phase portrait",xlabel="prey",ylabel="predator"); lines!(ax2,prey,pred,color=:slateblue)
out=joinpath(@__DIR__,"outputs"); mkpath(out); save(joinpath(out,"lv_cycle.png"),fig)
println("saved -> ",joinpath(out,"lv_cycle.png"))
