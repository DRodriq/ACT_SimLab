module Sim

using AlgebraicPetri
using DifferentialEquations

export simulate, role_total, roles, process_keys

# The "role" of a species (prey/predator/grass/...) is the first element of its (role, tile) name.
species_role(net, s)       = first(sname(net, s))
# The process behind a transition is the first element of its (process, location) name.
transition_process(net, t) = first(tname(net, t))

"""Distinct species roles present in a composed net (the keys `init_for` must cover)."""
roles(net) = unique(species_role(net, s) for s in 1:ns(net))

"""Distinct processes present in a composed net (the keys `rate_for` must cover)."""
process_keys(net) = unique(transition_process(net, t) for t in 1:nt(net))

"""
    simulate(net, rate_for, init_for, tspan; saveat=0.5)

Build the rate vector (by process) and initial state (by role) from plain dictionaries, then
integrate the mass-action ODE. `rate_for` is keyed by process name (and `:move_t`); `init_for`
by role. Discover the required keys with `process_keys(net)` / `roles(net)`.

We simulate `PetriNet(net)` (labels stripped) so `vectorfield` indexes state by integer
position; `rate_for`/`init_for` are resolved against the labelled `net` in that same order.
"""
function simulate(net, rate_for::AbstractDict, init_for::AbstractDict, tspan; saveat = 0.5)
    p  = [rate_for[transition_process(net, t)] for t in 1:nt(net)]
    u0 = [init_for[species_role(net, s)]       for s in 1:ns(net)]
    prob = ODEProblem(vectorfield(PetriNet(net)), u0, tspan, p)
    solve(prob, Tsit5(); saveat)
end

"""
    role_total(sol, net, r)

Total population of role `r` summed across all tiles, at each saved time.
"""
function role_total(sol, net, r)
    ix = findall(s -> species_role(net, s) == r, 1:ns(net))
    [sum(u[ix]) for u in sol.u]
end

end # module Sim
