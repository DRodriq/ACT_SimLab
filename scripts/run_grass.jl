# Grass experiment: walk the isolation ladder.
#   Rung 2: grass + prey (no predator)  -> should be Lotka-Volterra one trophic level down.
#   Rung 3: grass + prey + predator     -> does the oscillation survive a third level?
# Same geography, same stratify/simulate; only the process bundle changes.
#
# Run from sim_lab/ :  julia --project=. scripts/run_grass.jl

using SimLab
using AlgebraicPetri          # ns, nt
using CairoMakie

const N = 5
world = grid_world(N)

# ---- Rung 2: grass + prey ---------------------------------------------------------------
gp = stratify(assemble_local(GRASS_PREY; mobile = [:prey]), world)
println("grass+prey: ", ns(gp), " species, ", nt(gp), " transitions; roles=", roles(gp))
gp_rates = Dict(:grass_growth => 0.3, :grazing => 0.015, :prey_death => 0.7, :move_t => 0.05)
gp_init  = Dict(:grass => 100.0, :prey => 10.0)
sol_gp = simulate(gp, gp_rates, gp_init, (0.0, 100.0))
grass = role_total(sol_gp, gp, :grass)
prey1 = role_total(sol_gp, gp, :prey)
println("  grass: ", round(minimum(grass);digits=1), "..", round(maximum(grass);digits=1),
        "   prey: ", round(minimum(prey1);digits=1), "..", round(maximum(prey1);digits=1))

# ---- Rung 3: grass + prey + predator ----------------------------------------------------
eco = stratify(assemble_local(ECOSYSTEM; mobile = [:prey, :predator]), world)
println("ecosystem:  ", ns(eco), " species, ", nt(eco), " transitions; roles=", roles(eco))
eco_rates = Dict(:grass_growth => 0.3, :grazing => 0.02, :prey_death => 0.1,
                 :predation => 0.01, :predator_death => 0.3, :move_t => 0.05)
eco_init  = Dict(:grass => 50.0, :prey => 20.0, :predator => 8.0)
sol_eco = simulate(eco, eco_rates, eco_init, (0.0, 200.0))
g2 = role_total(sol_eco, eco, :grass)
p2 = role_total(sol_eco, eco, :prey)
d2 = role_total(sol_eco, eco, :predator)
println("  grass: ", round(minimum(g2);digits=1), "..", round(maximum(g2);digits=1),
        "  prey: ", round(minimum(p2);digits=1), "..", round(maximum(p2);digits=1),
        "  pred: ", round(minimum(d2);digits=1), "..", round(maximum(d2);digits=1))

# ---- plots ------------------------------------------------------------------------------
fig = Figure(size = (1000, 400))
ax1 = Axis(fig[1,1], xlabel="time", ylabel="population", title="grass + prey  (LV, one level down)")
lines!(ax1, sol_gp.t, grass, label="grass"); lines!(ax1, sol_gp.t, prey1, label="prey"); axislegend(ax1)
ax2 = Axis(fig[1,2], xlabel="time", ylabel="population", title="grass + prey + predator")
lines!(ax2, sol_eco.t, g2, label="grass"); lines!(ax2, sol_eco.t, p2, label="prey")
lines!(ax2, sol_eco.t, d2, label="predator"); axislegend(ax2)
out = joinpath(@__DIR__, "grass.png"); save(out, fig)
println("saved -> ", out)
