# Milestone-0 minimal run, on the refactored substrate.
#
# The set of processes you assemble is the ONE switch for isolation vs composition:
#     LV_PROCESSES                       -> full predator / prey
#     [:prey_birth]                      -> prey alone (no predator)
#     (later) grass/soil process names   -> the world below the animals, animals absent
# The geography, stratification, and simulation code below never change with that choice.
#
# Run from sim_lab/ :   julia --project=. scripts/run_mvp.jl

using SimLab
using AlgebraicPetri          # ns, nt for the printout
using CairoMakie

const N = 5

# 1. Local dynamics: pick the processes + which species may move. This line is the switch.
local_model = assemble_local(LV_PROCESSES; mobile = [:prey, :predator])

# 2. Stratify over an N x N world. Same call regardless of what's in local_model.
world = grid_world(N)
net   = stratify(local_model, world)
println("composed net: ", ns(net), " species, ", nt(net), " transitions (", N, "x", N, ")")
println("processes present: ", process_keys(net))   # the rate keys this net needs
println("roles present:     ", roles(net))           # the init keys this net needs

# 3. Parameters (by process) and initial state (by role). Tune here; nothing below changes.
rates = Dict(:prey_birth => 0.3, :predation => 0.015, :predator_death => 0.7, :move_t => 0.05)
init  = Dict(:prey => 100.0, :predator => 10.0)

sol = simulate(net, rates, init, (0.0, 100.0))

prey = role_total(sol, net, :prey)
pred = role_total(sol, net, :predator)
println("prey range: ", round(minimum(prey); digits=1), " .. ", round(maximum(prey); digits=1))
println("pred range: ", round(minimum(pred); digits=1), " .. ", round(maximum(pred); digits=1))

# 4. Plot.
fig = Figure(size = (900, 380))
ax1 = Axis(fig[1, 1], xlabel = "time", ylabel = "population", title = "Spatial LV — aggregate")
lines!(ax1, sol.t, prey, label = "prey")
lines!(ax1, sol.t, pred, label = "predator")
axislegend(ax1)
ax2 = Axis(fig[1, 2], xlabel = "prey", ylabel = "predator", title = "phase portrait")
lines!(ax2, prey, pred)
out = joinpath(@__DIR__, "lv_minimal.png")
save(out, fig)
println("saved plot -> ", out)
