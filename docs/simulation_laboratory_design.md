# Simulation Laboratory: System Design

A compositional simulation laboratory in the AlgebraicJulia ecosystem, starting from spatial Lotka-Volterra and scaling toward a Dwarf-Fortress-class open-world generator. This document is the working architectural reference; it will evolve as the laboratory teaches us what it actually needs to be.

## Guiding principles

**Composition over enumeration.** Subsystems are open systems with typed ports. Worlds are built by gluing subsystems along the spatial graph. Adding a new subsystem (weather, hydrology, herbivores) means writing one open system, not modifying a global update loop.

**Properties not types.** Tiles hold continuous property bundles. Biomes, regimes, and qualitative "kinds" are emergent clusters in state-space, identified post-hoc by analysis, not declared up front.

**Schema as a tunable artifact.** The schema — which properties exist, which subsystems are coupled, which processes are represented — is itself versioned and refinable. When tuning fails, the diagnostic protocol asks whether the schema can express the desired phenomenon at all.

**The harness is the product.** Instrumentation, characterization, scenario management, and diagnostic loops are first-class. The simulation engine is comparatively small; the laboratory around it is most of the work.

**Subsystem isolation before composition.** Every subsystem must be runnable alone, with degenerate environments, before being composed with others. Diagnostic clarity depends on this.

---

## The pipeline at a glance

```
┌──────────────────────────────────────────────────────────────────────────┐
│                          SCHEMA LAYER (Catlab)                           │
│                                                                          │
│   @present SchWorld(FreeSchema)                                          │
│     Tile, Edge, src/tgt, property attributes (moisture, temp, ...)       │
│     Versioned. Migrations are explicit functors between schema versions. │
└──────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                     WORLD GENERATION LAYER                               │
│                                                                          │
│   ACSet instance: tiles populated, edges built, properties assigned      │
│   Generators: Perlin noise, fractal terrain, hand-painted, replay        │
│   Output: a concrete World :: TileWorld ACSet                            │
└──────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                  SUBSYSTEM LAYER (AlgebraicPetri)                        │
│                                                                          │
│   Each subsystem = OpenPetriNet with boundary places                     │
│   - flora_local(props) -> OpenPetriNet                                   │
│   - fauna_local(props) -> OpenPetriNet                                   │
│   - diffusion_edge(perm) -> OpenPetriNet                                 │
│   - weather_regional(...) -> OpenPetriNet  (later)                       │
│   Rates are functions of tile/edge properties, not hardcoded constants.  │
└──────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────┐
│              COMPOSITION LAYER (structured cospans / oapply)             │
│                                                                          │
│   Functor: World ACSet -> diagram of open systems                        │
│     - each Tile -> local subsystems with that tile's properties          │
│     - each Edge -> diffusion process                                     │
│   oapply(diagram) :: closed PetriNet for the whole world                 │
└──────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────┐
│              SIMULATION LAYER (AlgebraicDynamics + DiffEq)               │
│                                                                          │
│   Petri net -> ODE system (or stochastic, or hybrid)                     │
│   DifferentialEquations.jl integrates                                    │
│   Callbacks emit state snapshots into the harness                        │
└──────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                          HARNESS LAYER                                   │
│                                                                          │
│   ParameterStore | TimeSeriesCapture | ScenarioRunner | SweepRunner      │
│   Characterization | Diagnostic | Visualization | AI-assist interface    │
└──────────────────────────────────────────────────────────────────────────┘
```

Each arrow is a stable interface. Replacing one layer's implementation (e.g., swapping deterministic LV for stochastic) doesn't disturb the others. That's what the categorical discipline buys.

---

## Layer detail

### 1. Schema layer

Defines the structure of a world without committing to specific dynamics. Lives in `src/schema/`.

The starting schema is minimal:

```julia
@present SchWorld(FreeSchema) begin
    Tile::Ob
    Edge::Ob
    src::Hom(Edge, Tile)
    tgt::Hom(Edge, Tile)

    Real::AttrType

    x::Attr(Tile, Real)            # spatial position (for rendering, not semantics)
    y::Attr(Tile, Real)
    moisture::Attr(Tile, Real)
    temperature::Attr(Tile, Real)
    fertility::Attr(Tile, Real)
    permeability::Attr(Edge, Real)  # diffusion resistance / barrier strength
end

@acset_type TileWorld(SchWorld, index=[:src, :tgt])
```

Critically: **no terrain types, no biome enumerations**. Forest-ness, desert-ness, etc. emerge from the dynamics on the property bundle.

Schema versioning: every world records the schema version under which it was generated. Migrations between schema versions are explicit functors, supported by Catlab's schema migration machinery. When you add `seasonality` as a new attribute, you write a migration that lifts old worlds into the new schema with a default value, and the harness keeps both versions runnable.

State variables (populations, accumulated quantities) added later belong to the simulation state, not the schema. The schema describes the *structural* world; the simulation produces trajectories over that structure.

### 2. World generation layer

Produces concrete ACSet instances of the schema. Lives in `src/world_gen/`.

For Lotka-Volterra starting point:
- Build an N×N grid of tiles with adjacency edges (4-connected or 8-connected).
- Assign properties via a generator:
  - **Constant** generator: same properties everywhere. Useful for isolating spatial dynamics from spatial heterogeneity.
  - **Gradient** generator: linear or radial property gradients. Tests how dynamics respond to smooth variation.
  - **Noise** generator: Perlin/simplex noise for naturalistic property fields.
  - **Painted** generator: load from image/file. Useful for crafted test scenarios.
  - **History-replay** generator: rerun a previous world's generation deterministically by seed.

Output is a `TileWorld` ACSet, fully specified, ready to be composed with subsystems.

The generator is a separate concern from dynamics. The same generated world can be run with different subsystem configurations, and the same subsystem configuration can be run on different generated worlds. This separation is essential for diagnostics.

### 3. Subsystem layer

Open Petri nets parameterized by tile or edge properties. Lives in `src/subsystems/`.

Each subsystem is a function from properties to an `OpenPetriNet`:

```julia
# Lotka-Volterra flora-fauna at a single tile
function lv_local(props::TileProps)
    α = growth_rate(props.moisture, props.fertility, props.temperature)
    β = predation_rate(props.temperature)
    γ = predator_death_rate(props.temperature)

    OpenPetriNet(
        LabelledPetriNet(
            [:prey, :predator],
            :birth     => (:prey       => (:prey, :prey)),
            :predation => ((:prey, :predator) => (:predator, :predator)),
            :death     => (:predator   => ())
        ),
        rates = (birth=α, predation=β, death=γ),
        boundary = [:prey, :predator]  # both diffuse across edges
    )
end

# Diffusion along an edge
function diffusion_edge(props::EdgeProps)
    d = props.permeability
    OpenPetriNet(...)  # transitions that move population between two boundary places
end
```

**Initial subsystems** (Lotka-Volterra milestone):
- `lv_local`: prey-predator dynamics at a tile.
- `diffusion_edge`: population flow between adjacent tiles.

**Near-term additions** (after milestone 1):
- `flora_growth`: plant biomass with property-dependent rates.
- `herbivore`: separated from predator, depends on flora directly.
- `carnivore`: top-level predator on herbivores.
- `weather_local`: temperature/moisture modulation per tile.

**Mid-term** (after spatial dynamics are tuned):
- `weather_regional`: slower-timescale weather operating on regions.
- `disturbance`: stochastic events (fire, storm, disease) that reset patches.
- `hydrology`: water flow across the spatial graph (rivers, lakes).
- `seasonality`: cyclic forcing on rate parameters.

**Long-term** (after the laboratory is mature):
- `agents`: trait-based creatures replacing typed species.
- `economy`: resource production, trade flows, settlements.
- `culture`: history, conflict, narrative artifacts ("story sift").

Each addition is an open system with declared boundary, slotted into the composition pipeline. The composition layer doesn't change.

### 4. Composition layer

Builds the world's total dynamics by gluing subsystems along the spatial graph. Lives in `src/composition/`.

The core function is roughly:

```julia
function compose_world(world::TileWorld, config::CompositionConfig)
    diagram = UWD()  # or a structured-cospan diagram
    for tile in parts(world, :Tile)
        props = tile_properties(world, tile)
        for sub in config.tile_subsystems
            add_box!(diagram, sub(props))
        end
    end
    for edge in parts(world, :Edge)
        props = edge_properties(world, edge)
        add_box!(diagram, config.edge_subsystem(props))
    end
    wire_boundaries!(diagram, world)
    oapply(diagram)  # collapse to a single PetriNet
end
```

`CompositionConfig` declares which subsystems are active. Running flora-only is the same code with a config that excludes fauna; running fauna with clamped flora is the same code with a config that includes both but holds flora at a fixed level. **Subsystem isolation is a config change, not a code branch.** This is the load-bearing payoff of the categorical structure.

Output: a closed Petri net (or a hybrid system if discrete events are included) ready for the simulation layer.

### 5. Simulation layer

Compiles the composed system to executable dynamics and integrates. Lives in `src/sim/`.

```julia
sys = compose_world(world, config)
prob = ODEProblem(sys, initial_state, tspan, parameters)
sol = solve(prob, Tsit5(), callback=harness_callback)
```

Three integration modes will be supported:
- **Deterministic ODE**: classical, fast, reproducible.
- **Stochastic SDE / Gillespie**: demographic noise, rare events. Essential once disturbance regimes matter.
- **Hybrid**: continuous dynamics with discrete event injections. Required for disturbances, agent actions, history events.

The simulation layer is mostly a thin wrapper over `DifferentialEquations.jl`. Most complexity lives in callbacks that emit state to the harness.

### 6. Harness layer

Where the laboratory actually lives. Lives in `src/harness/`.

#### ParameterStore

Single source of truth for every tunable constant. Hierarchically addressable, versioned, serializable.

```julia
params = ParameterStore()
params["subsystems.lv.rates.predation"] = 0.02
params["world_gen.noise.octaves"] = 4
params["composition.tile_subsystems"] = [:lv_local]
```

Snapshots, diffs, and version pinning all live here. Both human and AI-assisted tuning read and write through this interface.

#### TimeSeriesCapture

Per-tile and aggregate state captured at configurable rates. Backed by a columnar store (probably DataFrames + Arrow, or a small SQLite for queryability).

Key design point: **sample, don't record everything**. Default to global aggregates every tick, per-tile state every N ticks, full snapshots at scenario-defined waypoints. Adjustable per-run.

#### ScenarioRunner

A scenario is `(schema_version, world_gen_config, composition_config, parameter_snapshot, initial_state, duration, capture_config)`. Scenarios are first-class artifacts — saved, named, replayed, compared.

```julia
scenario = Scenario(
    name = "flora_only_smooth_gradient",
    schema = "v0.3",
    world_gen = NoiseWorld(seed=42, octaves=4),
    composition = CompositionConfig(tile_subsystems=[:flora_growth]),
    params = params,
    duration = 1000.0,
    capture = CaptureConfig(global_every=1, tile_every=10)
)
result = run(scenario)
```

#### SweepRunner

Run many scenarios in parallel, varying parameters or seeds. Returns a `SweepResult` that holds all the time series, ready for comparison.

```julia
sweep = ParameterSweep(
    base = scenario,
    vary = (:subsystems => :lv => :predation, 0.005:0.005:0.05)
)
sweep_result = run(sweep, workers=8)
```

#### Characterization

Functions from `RunResult` to structured summaries. Examples:
- Cluster the tile-state trajectories; count clusters; describe centroids.
- Compute time-to-equilibrium, oscillation period, attractor type.
- Spatial statistics: patch size distribution, fragmentation index, ecotone width.
- Regime classifier: which qualitative regime is this in?

Characterizations are the vocabulary in which "looks right" gets made precise. They start as ad-hoc analyses you find yourself running repeatedly, then get codified.

#### Diagnostic

Given `(scenario, observed_characterization, desired_characterization)`, propose hypotheses for what to change and at what layer:
- World-generation issue (try the same dynamics on a different world)
- Parameter issue (sweep to find a regime where the desired behavior appears)
- Subsystem-structural issue (is there a missing brake / coupling / feedback?)
- Schema-expansion issue (no parameter setting can produce the behavior — need new schema dimension)
- Composition issue (which subsystem in isolation produces the symptom?)

Initially a checklist and a set of helper functions. Eventually the entry point for AI-assisted tuning loops.

#### Visualization layer

Detailed separately below — large enough to deserve its own section.

---

## Visualization and rendering

The renderer is not a polish task — it's a primary diagnostic instrument. Most insight in this kind of work comes from looking, and without good visualization you can't tell when something interesting is happening.

### Three rendering modalities

**Live spatial view.** A real-time (or near-real-time) heatmap/animated view of the spatial grid as the simulation runs. Shows current property fields, current state variables (populations), or derived quantities (e.g., predator-to-prey ratio per tile). User selects which channel to color by. Built with `Makie.jl` (specifically `GLMakie` for interactivity); supports playback controls, scrubbing, layer toggling. The simulation can run in the background and the view samples its state.

**Phase-space view.** For dynamical analysis. Per-tile or aggregate state plotted as trajectories in state-space (e.g., prey vs predator). Shows attractors, limit cycles, fixed points. Multiple runs overlaid for comparison. Essential for parameter-sweep analysis.

**Run summary dashboard.** Static, generated after a run completes. Time series of aggregates, spatial snapshots at waypoints, characterization summary, parameter values, diff against previous run. Markdown + embedded images, browsable. Critical for the "tweak, observe, iterate" loop because it makes each run comparable to the last.

### Architecture

```
        Simulation (running)
              │
              ▼ callbacks
        TimeSeriesCapture
              │
       ┌──────┼──────┐
       ▼      ▼      ▼
    Live    Phase   Summary
    view    space   dashboard
   (Makie) (Makie) (Markdown+SVG)
```

The visualization layer is a *reader* of the harness, not coupled to the simulation directly. This means:
- Visualizations can be regenerated from saved runs without rerunning.
- New visualization types can be added without touching simulation code.
- A future web-based front-end (for "open the world to agents") consumes the same data.

### What to render in the first milestone

For the Lotka-Volterra starting scenario:
- Heatmap of prey density (channel-toggleable to predator, ratio, total biomass).
- Total prey and predator populations over time (line plot, aggregate).
- Phase-space plot: aggregate prey vs predator trajectory.
- Optional: per-tile small-multiples of population time series, for spatially heterogeneous worlds.

Everything beyond this is added when the laboratory demands it.

---

## Module layout

```
src/
├── schema/
│   ├── v0_1.jl              # initial schema
│   ├── v0_2.jl              # adds seasonality (example future version)
│   └── migrations.jl
├── world_gen/
│   ├── generators.jl        # Constant, Gradient, Noise, Painted
│   └── seeds.jl
├── subsystems/
│   ├── lv.jl                # initial Lotka-Volterra
│   ├── diffusion.jl
│   ├── flora.jl             # (future) flora-only with property-dependent growth
│   ├── fauna.jl             # (future) trophic levels
│   ├── weather.jl           # (future)
│   └── disturbance.jl       # (future)
├── composition/
│   ├── compose.jl           # build diagram from world + config
│   └── config.jl            # CompositionConfig
├── sim/
│   ├── integrate.jl         # ODE/SDE/hybrid drivers
│   └── callbacks.jl         # emit state to harness
├── harness/
│   ├── params.jl            # ParameterStore
│   ├── capture.jl           # TimeSeriesCapture
│   ├── scenarios.jl         # Scenario, ScenarioRunner
│   ├── sweeps.jl            # ParameterSweep, SweepRunner
│   ├── characterize.jl      # characterization functions
│   ├── diagnose.jl          # diagnostic protocols
│   └── store.jl             # persistence
├── viz/
│   ├── live.jl              # GLMakie real-time view
│   ├── phase.jl             # phase-space plots
│   ├── dashboard.jl         # run summary generator
│   └── theme.jl
└── ai/                      # later
    ├── propose.jl           # parameter proposals from observations
    ├── narrate.jl           # story-sift / log-to-prose
    └── search.jl            # closed-loop optimization

test/
├── unit/                    # standard Julia tests
├── subsystem_isolation/     # each subsystem alone, with synthetic inputs
├── pairwise_composition/    # two subsystems composed, others clamped
├── regression/              # characterization-based: "this scenario should produce this regime"
└── invariants/              # conservation laws, monotonicity, sanity
```

---

## Integration testing

Integration testing is non-standard here and needs deliberate design, because the system's outputs are emergent dynamics, not return values.

### Four layers of testing

**Unit tests.** Standard Julia testing. Pure functions, schema validation, parameter parsing, individual rate functions. Fast, deterministic, run on every commit.

**Subsystem isolation tests.** Each subsystem run alone, with its inputs set to synthetic values, asserting properties of its output behavior. Example: "flora alone with constant moisture and no consumers reaches a logistic steady state within 500 ticks, within 5% of theoretical carrying capacity." These tests are *characterization tests* — they assert that the dynamics produce a recognizable regime, not exact numerical values.

**Pairwise composition tests.** Each pair of subsystems run with all others clamped. Tests the *interface* between them. Example: "flora and herbivore composed, with all other subsystems off, produces sustained oscillation in some parameter regime." If a pairwise test fails after adding a new subsystem, the integration with that subsystem is the issue.

**Regression scenarios.** Named scenarios with declared expected characterizations. "Scenario `lv_grid_baseline_v1` should produce: total prey oscillation amplitude in [X, Y], cluster count >= 2, no extinction events." These are the laboratory's golden-master tests. They catch when a change to one subsystem unexpectedly alters another's behavior.

**Invariant tests.** Properties that must hold regardless of parameter choice. Conservation laws (if you've designed your system to conserve something, verify it). Non-negativity of populations. Monotonicity where expected. These run on every scenario as background checks.

### CI workflow

1. Unit tests on every commit (seconds).
2. Subsystem isolation tests on every PR (minutes).
3. Pairwise composition tests on every PR (minutes).
4. Regression scenarios on every merge to main (tens of minutes; runs the actual sims).
5. Invariant checks run inline with every simulation, asserting at runtime.

### Characterization-based assertions

The core difficulty: how do you assert that a simulation "looks right"? Two complementary approaches:

**Statistical assertions on aggregates.** "Mean prey population in `[10000, 15000]` over the last half of the run." "Oscillation period in `[40, 80]` ticks." These are robust but coarse.

**Topological/qualitative assertions.** "Number of attractor basins detected >= 2." "Spatial autocorrelation length < 5 tiles." "Phase-space trajectory winds around fixed point at least 3 times." These capture the qualitative regime, but are harder to write.

Build a small DSL for these as you go. They become your "looks right" vocabulary, and they're what AI assistance ultimately learns to evaluate.

---

## Build-out roadmap

### Milestone 0: pipeline skeleton (days)

Two tiles, one edge, LV on each, diffusion between. Goal: every layer in the pipeline talks to every other layer. No spatial structure beyond two tiles. Crude visualization (just plot populations).

**Deliverable:** A `run_minimal.jl` script that produces an animation and a phase plot.

### Milestone 1: spatial LV with property-dependent rates (weeks)

50×50 grid. Property bundle on tiles (moisture, temperature, fertility). LV rates depend on properties. World generated by Perlin noise. Heatmap visualization, aggregate time series, phase-space plot. Parameter store and time-series capture working end-to-end. One sweep over `predation_rate` × `diffusion_coefficient` producing a sweep dashboard.

**Deliverable:** First report from the laboratory: "across the property landscape, what regimes does spatial LV produce?"

### Milestone 2: characterization and diagnostic loop (weeks)

Implement initial characterizations: cluster tiles by trajectory, identify regimes, summarize. Implement diagnostic checklist. Add subsystem isolation harness. Build run-summary dashboards.

**Deliverable:** When the laboratory shows something unexpected, you can systematically determine whether it's a parameter, schema, or composition issue.

### Milestone 3: subsystem expansion (weeks to months)

Refactor LV into flora + herbivore + carnivore as separate subsystems. Verify in isolation, pairwise, composed. Add weather as the first multi-scale subsystem. Add seasonal forcing.

**Deliverable:** Worlds with three trophic levels, weather, and seasonal cycles, with all integration tests passing.

### Milestone 4: stochasticity and disturbance (months)

Switch integration to Gillespie or hybrid where appropriate. Add disturbance regimes (random patch resets, fires propagating along moisture gradients). Verify that disturbance produces the spatial heterogeneity that purely deterministic dynamics lacked.

**Deliverable:** Patchy, dynamic worlds with realistic-feeling temporal variability.

### Milestone 5: AI-assisted tuning (months)

Wire the parameter store and characterization layer to an AI-assist interface. Initially: AI proposes parameter changes given observed vs desired characterizations; human approves. Later: closed-loop search over parameter space with AI-evaluated "looks right" judgments.

**Deliverable:** A laboratory where you describe what you want to see and the system iterates toward it.

### Milestone 6+: the open-world frontier

Trait-based agents replacing typed species. Hydrology. Geology and history. Settlements and economy. Story-sift. Agent-playable worlds.

These are years of work and the architecture must support them without rewrites. The categorical discipline is the bet that it will.

---

## Key risks and watch-points

**AlgebraicJulia maturity.** The ecosystem is research-grade. Plan for rough edges, undocumented behavior, and version churn. Pin versions in `Project.toml` aggressively. Engage the Zulip community early.

**Composition performance.** `oapply` on large diagrams can be slow at compose-time. Profile early. Cache composed systems by world+config hash; only recompose when the world or config changes.

**The temptation to over-engineer the substrate.** The categorical structure invites years of refinement before any dynamics run. Resist. Milestone 0 should be done in days, not weeks. Ugly working code beats elegant non-running code.

**Characterization is the hard problem.** "Looks right" is the laboratory's final boss. Plan for the characterization vocabulary to evolve continuously. Don't try to design it up front; let it emerge from repeated need.

**Schema growth.** Each new schema dimension multiplies the tuning surface. Add dimensions only when current ones provably cannot produce a desired phenomenon. Use the diagnostic protocol; don't add speculatively.

**Visualization debt.** Without good visualization, the laboratory can't be steered. Invest in viz at every milestone, not just at the end. Bad heatmaps hide everything.

---

## What this document is not

It's not a specification. It's a working hypothesis about the right architecture, written down so it can be tested by reality and revised. The categorical structure is the part most likely to survive contact with the project; the specific module layout, naming, and milestone ordering are the parts most likely to change. Treat the document as living. Commit it to the repo, edit it as you learn, keep its predictions honest by tracking which ones held.
