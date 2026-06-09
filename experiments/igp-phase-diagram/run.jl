# Experiment: IGP phase diagram (our Holt–Polis map)
# Question: How does the intraguild-predation outcome (fox wins / wolf wins / coexist) depend on fox
#           competitiveness (sheep→fox attack rate) × productivity (grass carrying capacity)?
# Run: julia --project=. experiments/igp-phase-diagram/run.jl   → outputs/phase_diagram.png

using SimLab, CairoMakie

B = Currency(:biomass, false)                     # one currency, open
base = Scenario([B],
    [Pool(:grass,:producer,[1.0],0.0,0.0,0.02,[1.0],0.0),
     Pool(:sheep,:consumer,[1.0],0.0,0.10,0.0,[0.0],0.0),
     Pool(:fox,  :consumer,[1.0],0.0,0.06,0.0,[0.0],0.0),
     Pool(:wolf, :consumer,[1.0],0.0,0.05,0.0,[0.0],0.0),
     Pool(:detritus,:dead, [1.0],0.0,0.0,0.0,[0.0],0.0)],
    [Feed(:grass,:sheep,0.2,1.0,0.1), Feed(:sheep,:fox,0.2,1.0,0.1),   # IGP: wolf eats sheep AND fox
     Feed(:sheep,:wolf,0.2,1.0,0.1), Feed(:fox,:wolf,0.2,1.0,0.1)],
    :detritus, Dict(:grass=>[5.0],:sheep=>[1.0],:fox=>[0.3],:wolf=>[0.3],:detritus=>[0.0]), [0.0])

foxrate = collect(0.1:0.05:1.2)                   # fox competitiveness (sheep→fox rate)
crowd   = collect(0.012:0.004:0.06)               # grass crowd (↓ = higher carrying capacity)
M = sweep2(base,
    ("sheep→fox",  foxrate, (s,v)->set_feed(s,:sheep,:fox,:rate,v)),
    ("grass crowd",crowd,   (s,v)->set_pool(s,:grass,:crowd,v));
    living=[:grass,:sheep,:fox,:wolf], T=900.0)

cat(c)=(s=Set(c.surviving); f=:fox in s; w=:wolf in s; f&&w ? 3 : f ? 2 : w ? 1 : 0)
catname=["neither","wolf wins","fox wins","coexist"]; catcol=Makie.wong_colors()[[6,1,2,3]]
C=[cat(M[i,j]) for i in 1:length(foxrate), j in 1:length(crowd)]

@assert all(c.conserved for c in M)               # GATE: biomass conserved in every run
println("IGP phase diagram: ",length(M)," runs, all conserved.  ",
        join([string(catname[k+1],"=",count(==(k),C)) for k in 0:3], "  "))

fig=Figure(size=(780,520))
ax=Axis(fig[1,1],title="IGP phase diagram (Holt–Polis)",
    xlabel="fox competitiveness  (sheep→fox rate)",ylabel="grass crowd  (↓ = more productive)",yreversed=true)
heatmap!(ax,foxrate,crowd,C,colormap=cgrad(catcol,4,categorical=true),colorrange=(-0.5,3.5))
Colorbar(fig[1,2],colormap=cgrad(catcol,4,categorical=true),colorrange=(-0.5,3.5),ticks=(0:3,catname))
out=joinpath(@__DIR__,"outputs"); mkpath(out); save(joinpath(out,"phase_diagram.png"),fig)
println("saved -> ",joinpath(out,"phase_diagram.png"))
