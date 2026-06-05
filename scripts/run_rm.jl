# Rosenzweig-MacArthur: does grass carrying capacity rescue the collapsed predator?
# And sweep K (grass carrying capacity) to see the regime change:
#   small K -> strong self-limitation -> damped to a stable coexistence point
#   larger K -> enrichment -> sustained limit cycle (paradox of enrichment)
#   too large -> large cycles grazing zero -> extinction risk
# K is set via the crowding rate c = r/K  (logistic dG/dt = rG(1 - G/K)).
#
# Run from sim_lab/ :  julia --project=. scripts/run_rm.jl

using SimLab
using AlgebraicPetri          # ns, nt
using CairoMakie

const N = 5
world = grid_world(N)

# grass immobile; prey & predator move. RM = grass self-limits.
net = stratify(assemble_local(ECOSYSTEM_RM; mobile = [:prey, :predator]), world)
println("RM ecosystem: ", ns(net), " species, ", nt(net), " transitions")
println("processes: ", process_keys(net))

r = 0.3
base = Dict(:grass_growth => r, :grazing => 0.02, :prey_death => 0.1,
            :predation => 0.02, :predator_death => 0.2, :move_t => 0.05)
init = Dict(:grass => 20.0, :prey => 10.0, :predator => 5.0)
Ks   = [20.0, 50.0, 150.0, 600.0]

fig = Figure(size = (1100, 750))
for (i, K) in enumerate(Ks)
    rates = merge(base, Dict(:grass_crowding => r / K))      # c = r/K
    sol = simulate(net, rates, init, (0.0, 400.0); saveat = 1.0)
    g = role_total(sol, net, :grass)
    p = role_total(sol, net, :prey)
    d = role_total(sol, net, :predator)
    println("K=", Int(K),
            "  grass ", round(minimum(g);digits=1), "..", round(maximum(g);digits=1),
            "  prey ",  round(minimum(p);digits=1), "..", round(maximum(p);digits=1),
            "  pred ",  round(minimum(d);digits=1), "..", round(maximum(d);digits=1))
    row, col = (i - 1) ÷ 2 + 1, (i - 1) % 2 + 1
    ax = Axis(fig[row, col], xlabel = "time", ylabel = "population", title = "K = $(Int(K))")
    lines!(ax, sol.t, g, label = "grass")
    lines!(ax, sol.t, p, label = "prey")
    lines!(ax, sol.t, d, label = "predator")
    i == 1 && axislegend(ax; position = :rt)
end
out = joinpath(@__DIR__, "rm_sweep.png"); save(out, fig)
println("saved -> ", out)
