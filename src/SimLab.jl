module SimLab

include("schema.jl")
include("world_gen.jl")
include("ontology.jl")
include("subsystems.jl")
include("composition.jl")
include("sim.jl")
include("viz.jl")
include("harness.jl")

using .Schema
using .WorldGen
using .Ontology
using .Subsystems
using .Composition
using .Sim
using .Viz
using .Harness

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
# Harness: currency-agnostic engine, the Scenario forcing layer, characterization (classify/sweep)
export Currency, Pool, Feed, Scenario, run_scenario, classify, sweep2, set_pool, set_feed, drifts, ssize, ssize_end
# Spatial layer: distribute a Scenario over an N×N grid + diffuse mobile pools
export grid_edges, generate_spatial, run_spatial, drifts_spatial, role_field

end # module SimLab
