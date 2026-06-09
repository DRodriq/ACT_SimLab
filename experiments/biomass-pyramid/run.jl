# Experiment: biomass-pyramid — conversion efficiency ε sets the predator:prey ratio
# Question: does Lindeman efficiency control whether standing biomass pyramids (pred<prey) or inverts?
# Run: julia --project=. experiments/biomass-pyramid/run.jl   → outputs/pyramid.png

using SimLab, CairoMakie

B = Currency(:biomass, false)
lv(eps) = Scenario([B],
    [Pool(:prey,:producer,[1.0],0.0,0.0,0.0,[0.6],0.0),    # birth α = 0.6 (free food)
     Pool(:pred,:consumer,[1.0],0.0,0.5,0.0,[0.0],0.0),    # death  γ = 0.5
     Pool(:detritus,:dead,[1.0],0.0,0.0,0.0,[0.0],0.0)],
    [Feed(:prey,:pred,0.5,1.0,eps)],                        # conversion efficiency ε = assim
    :detritus, Dict(:prey=>[6.0],:pred=>[1.0],:detritus=>[0.0]), [0.0])

epsv=collect(0.1:0.05:1.0)
res=map(epsv) do e
    sol,L=run_scenario(lv(e);T=300.0); h=length(sol.u)÷2
    pa=sum(ssize(u,L,L.pidx[:prey]) for u in sol.u[h:end])/length(sol.u[h:end])
    qa=sum(ssize(u,L,L.pidx[:pred]) for u in sol.u[h:end])/length(sol.u[h:end])
    _,od=drifts(sol,L); (qa/pa, all(<(1e-6),od))
end
ratios=first.(res); cons=all(last.(res))
@assert cons && ratios[1]<1.0 && ratios[end]>1.0          # GATE: pyramid at low ε, inverts at high ε
println("biomass-pyramid: ε=0.1 → pred/prey=",round(ratios[1];digits=2),
        "   ε=1.0 → ",round(ratios[end];digits=2)," (predicted εα/γ; conserved)")

fig=Figure(size=(580,400))
ax=Axis(fig[1,1],title="conversion efficiency sets the pyramid",xlabel="conversion efficiency ε",ylabel="predator / prey (biomass)")
lines!(ax,epsv,ratios,color=:firebrick); hlines!(ax,[1.0],color=(:black,0.4),linestyle=:dash)
text!(ax,0.14,1.08,text="inverted (pred > prey)",fontsize=10); text!(ax,0.14,0.35,text="pyramid (pred < prey)",fontsize=10)
out=joinpath(@__DIR__,"outputs"); mkpath(out); save(joinpath(out,"pyramid.png"),fig)
println("saved -> ",joinpath(out,"pyramid.png"))
