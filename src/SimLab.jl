module SimLab

include("schema.jl")
include("world_gen.jl")
include("ontology.jl")
include("subsystems.jl")
include("composition.jl")
include("sim.jl")
include("viz.jl")

using .Schema
using .WorldGen
using .Ontology
using .Subsystems
using .Composition
using .Sim
using .Viz

# Schema
export TileWorld, SchTileWorld
# World generation
export grid_world
# Process vocabulary
export ONTOLOGY, MOVE_TYPE, interaction_types
# Local-model assembly (subset of processes = subsystem isolation)
export Process, PROCESSES, LV_PROCESSES, GRASS_PREY, ECOSYSTEM, ECOSYSTEM_RM, assemble_local
# Composition over the spatial graph
export geography, stratify
# Simulation + introspection
export simulate, role_total, roles, process_keys
# Visualization (NOTE: still positional — pending name-based rewrite, see docs/journal.md)
export plot_aggregate, plot_phase, animate_grid

end # module SimLab
