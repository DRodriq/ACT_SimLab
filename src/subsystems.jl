module Subsystems

using AlgebraicPetri, AlgebraicPetri.TypedPetri
using Catlab, Catlab.Programs, Catlab.WiringDiagrams, Catlab.CategoricalAlgebra
using ..Ontology

export Process, PROCESSES, LV_PROCESSES, GRASS_PREY, ECOSYSTEM, ECOSYSTEM_RM, assemble_local

# A local process: a transition of some ontology `type` (shape), wired to named `species` in
# (inputs..., outputs...) port order. `name` becomes the transition's label in the local model.
struct Process
    name::Symbol
    type::Symbol
    species::Vector{Symbol}
end

# Registry of available processes. Add grass/soil/water processes here; nothing downstream
# (geography, stratification, simulation) needs to change when you do.
const PROCESSES = Dict{Symbol,Process}(
    # Two-species Lotka-Volterra (prey reproduces for free; "unlimited food" assumption).
    :prey_birth     => Process(:prey_birth,     :birth_t, [:prey, :prey, :prey]),
    :predation      => Process(:predation,      :pred_t,  [:prey, :predator, :predator, :predator]),
    :predator_death => Process(:predator_death, :death_t, [:predator]),
    # Grass layer: makes "prey's food" explicit. grazing REPLACES prey_birth — prey now
    # reproduces by eating grass. Every shape is reused; no ontology change.
    :grass_growth   => Process(:grass_growth,   :birth_t, [:grass, :grass, :grass]),       # grass -> 2 grass
    :grass_crowding => Process(:grass_crowding, :crowd_t, [:grass, :grass, :grass]),       # grass + grass -> grass (logistic)
    :grazing        => Process(:grazing,        :pred_t,  [:grass, :prey, :prey, :prey]),   # grass + prey -> 2 prey
    :prey_death     => Process(:prey_death,     :death_t, [:prey]),                          # prey -> .
)

# Named bundles = subsystems. Running a subset of processes is how you isolate/compose.
const LV_PROCESSES = [:prey_birth, :predation, :predator_death]
# grass + prey alone: this is Lotka-Volterra one trophic level down (grass=resource, prey=consumer).
const GRASS_PREY   = [:grass_growth, :grazing, :prey_death]
# Full tri-trophic chain: grass -> prey -> predator (exponential grass — fragile).
const ECOSYSTEM    = [:grass_growth, :grazing, :prey_death, :predation, :predator_death]
# Rosenzweig-MacArthur version: grass self-limits (carrying capacity) -> stabilized chain.
const ECOSYSTEM_RM = [:grass_growth, :grass_crowding, :grazing, :prey_death, :predation, :predator_death]

"""
    assemble_local(process_names; mobile=Symbol[])

Build a typed single-patch Petri net from a chosen set of processes (by name) plus the set of
species allowed to move between patches. Returns an `ACSetTransformation` into `ONTOLOGY`, ready
to `stratify`. Choosing a *subset* of processes is how you run a subsystem in isolation.
"""
function assemble_local(process_names::AbstractVector{Symbol};
                        mobile::AbstractVector{Symbol} = Symbol[])
    procs   = [PROCESSES[n] for n in process_names]
    species = unique(vcat([p.species for p in procs]..., collect(mobile)))
    sidx    = Dict(s => i for (i, s) in enumerate(species))

    uwd = RelationDiagram(repeat([:Pop], length(species)))
    js  = Int[]
    for (i, s) in enumerate(species)
        j = add_junction!(uwd, :Pop, variable = s)
        set_junction!(uwd, ports(uwd, outer = true)[i], j, outer = true)
        push!(js, j)
    end
    tnames = Symbol[]
    for p in procs
        box = add_box!(uwd, repeat([:Pop], length(p.species)), name = p.type)
        for (port, sp) in zip(ports(uwd, box), p.species)
            set_junction!(uwd, port, js[sidx[sp]])
        end
        push!(tnames, p.name)
    end
    model = oapply_typed(ONTOLOGY, uwd, tnames)

    # Mobile species get a :move_t self-loop so movement transitions appear under stratification.
    # Indexed by the model's own species names (robust to oapply's species ordering).
    ms   = dom(model)
    refl = [sname(ms, i) in mobile ? [MOVE_TYPE] : Symbol[] for i in 1:ns(ms)]
    add_reflexives(model, refl, ONTOLOGY)
end

end # module Subsystems
