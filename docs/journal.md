# Simulation Laboratory — Engineering Journal

A running lab notebook: mechanisms discovered, decisions taken, and *why*. Distinct from
`simulation_laboratory_design.md` (the architectural hypothesis) — this file records what
contact with the tools actually taught us, including the dead ends, so we don't re-learn them.

Entries are dated, newest at the bottom. Each decision should record the alternatives
considered and the reason for rejection, not just the conclusion.

---

## 2026-06-02 — First light: getting `SimLab` to precompile and compose

### Context

Starting state: package skeleton with `module SimLab` including six submodules. `using SimLab`
failed precompilation. Goal of the session: get the Milestone-0 pipeline
(`grid_world → compose_world → simulate → viz`) to actually run, and — more importantly —
decide whether the composition substrate the design doc bets on is the *right* one.

### Bug cascade (mechanisms worth remembering)

These cost real time because the error messages pointed away from the cause:

1. **`SimLab did not define the expected module 'SimLab'`** — *not* a typo in the module name.
   Three included files (`schema.jl`, `world_gen.jl`, `subsystems.jl`) were empty (0 bytes), so
   their submodules were never created; the `using .Schema` lines then threw, aborting the
   `module SimLab … end` body *before* the `SimLab` binding was registered. Julia's precompile
   check reports the generic "did not define the expected module," masking the real cause.
   **Lesson:** an empty `include` is a silent no-op; this error usually means "the module body
   threw," not "you misspelled the module."

2. **`Catlab.Present` does not exist** in Catlab 0.17.5. `@present`, `FreeSchema`, and `Hom` all
   come through plain `using Catlab` (via `@reexport using GATlab`). There is no `Present`
   submodule to import.

3. **`Hom` typo** (`Home`) and a duplicated/incomplete `export` line in `schema.jl`.

4. **`@acset_type Name(Sch, index=[…]){Float64}`** — the inline `{Float64}` curly *is* valid;
   the macro parses `Expr(:curly, …)` and generates `const Name = gensym{Float64}`.
   (ACSets `DenseACSets.jl:198`.) Not a bug; noting it because it looked like one.

5. **`vectorify` 1-tuple quirk** (AlgebraicPetri `AlgebraicPetri.jl:26`):
   `vectorify(n::Tuple) = length(n) == 1 ? [n] : n`. A single-species transition written as
   `(:prey,)` becomes `[(:prey,)]` — the whole tuple as one element — and the species lookup
   then fails with `KeyError: (:prey,)`. **Convention:** single species → bare symbol/index
   (`:prey`, `1`), never a 1-tuple. Multi-species → tuple.

All five are fixed; `SimLab` precompiles, `grid_world`, `lv_local`, `diffusion_edge` construct.

### The real finding: `oapply` glues by foot *equality*, and labels poison it

The composition step (`oapply` over a UWD) failed with `Feet of cospans are not equal:
[:prey_in] != [:prey]`. Root cause, confirmed in source:

- `oapply` identifies species at a shared junction by requiring **every leg's foot ACSet to be
  equal** (`Catlab .../wiring_diagrams/Algebras.jl:100`).
- The convenience constructor `Open(p::LabelledPetriNet, legs...)` names each **foot after its
  internal species** (`AlgebraicPetri.jl:466`). No decoupling.

So an `lv` box presents foot `:prey` at a tile's prey-junction, while a `diff` box presents
`:prey_in` / `:prey_out` at the *same* junction → not equal → error. And it can't be renamed
away: a diffusion edge touches **two distinct** prey junctions (src tile, tgt tile), so it needs
two distinct internal prey species — they can't both be the single label `:prey` in one
`LabelledPetriNet`. **`LabelledPetriNet` + structured-cospan `oapply` cannot express directed
inter-patch transport.** This is structural, not a typo.

### Decision: composition substrate

Three candidates evaluated against the project's actual mandate — *scale by the inherent
concepts of the tools*, because the composition substrate is the load-bearing bet of the whole
project. "Ugly working code" is the wrong standard *here* (it is fine for the harness/viz, not
for the substrate).

**(A) Unlabelled `PetriNet` + positional `oapply`.** — VERIFIED WORKS, REJECTED.
Anonymous single-species feet are all the identical `PetriNet(1)`, so they always match
(`TypedPetri.jl:44`); gluing is driven purely by junctions. Spike result: 2 tiles + 1 edge →
4 species, 8 transitions, exactly right. Composite species are positional (`prey@tile t =
2(t-1)+1`), which happens to match `viz.jl`'s existing indexing.
*Rejected because:* species/transition identity is carried by integer position across the whole
composite. At Milestone 0 (2 tiles) that's fine; by Milestone 3 (flora + herbivore + carnivore +
weather × hundreds of tiles) you are tracking thousands of parts by index with no names or types.
That is the conceptual non-scaling we were explicitly warned off. Keep only as a throwaway
sanity check that the pipeline *can* close.

**(B) `oapply_typed` (typed Petri over a UWD).** — Viable, partial fit.
Define a type-system net (the stable vocabulary: species types + transition types); each UWD box
is a transition *type*; junctions are typed species. Result preserves species/transition
**names and types** (`TypedPetri.jl:90-94`). Scales in the sense that identity is principled.
*Limitation:* still enumerates one box per tile and per edge in the UWD — the spec grows with the
world. Right tool when tiles have *structurally different* subsystem sets; overkill when every
tile runs the same dynamics.

**(C) Stratification via `typed_product` + `add_reflexives`.** — RECOMMENDED, **VALIDATED**.
The documented "workhorse of stratification" (`TypedPetri.jl:216`). Define the single-patch LV
dynamics **once** (typed over a shared type system) and the **geography** as a second typed net
(species = tiles, transitions = movement along edges) derived directly from the `TileWorld`
ACSet, then `typed_product` them. `add_reflexives` supplies the self-transitions that make the
product place LV interactions *within* a patch and movement *between* patches (the
`*----*` ⊗ `*----*` → grid picture in the `add_reflexives` docstring).
*Why it scales:* the dynamics spec is O(1) in grid size; grid size and topology live **entirely**
in the geography net, which is a mechanical image of the world graph. 5×5 vs 500×500 changes only
the geography net. Names/types are preserved end-to-end. Property-dependent rates attach
afterward (`add_params`), indexed by (transition-type, patch) — which is exactly the design doc's
"rates as a tunable artifact," and *strengthens* it (rates are no longer frozen into the net).

**Verdict:** target architecture is **(C)**. (B) is the fallback for genuinely heterogeneous-
structure worlds. (A) is rejected as a substrate.

### Implications for `simulation_laboratory_design.md`

The subsystem-layer sketch is the part that needs revising — it imagines
`OpenPetriNet(LabelledPetriNet(...), rates=…, boundary=[:prey,:predator])`, i.e. *labelled* nets
with *named* boundary places. That is precisely the shape that does not compose, and the
constructor doesn't exist. Under (C):
- A subsystem is a **typed Petri net** (an `ACSetTransformation` into the shared type system),
  not a labelled open net with named feet.
- The composition layer is **stratification** (`typed_product`), with the world ACSet supplying
  the geography factor — a cleaner realization of the doc's "Functor: World ACSet → diagram of
  open systems" than a hand-built UWD.
- Rates move out of the subsystem and into a post-composition parameter assignment from
  tile/edge properties. (Good: matches the `ParameterStore` philosophy.)
The categorical *discipline* the doc bets on survives intact; the specific subsystem API changes.

### Stratification spike result (approach C, 5×5 grid)

Template followed: AlgebraicPetri `docs/literate/epidemiology/disease_strains.jl`
(`oapply_typed` → `add_reflexives` → `typed_product`), with an **LV-shaped ontology** (the
infectious ontology's shapes don't fit LV's birth 1→2 / death 1→0, so a bespoke type system is
needed):

```
LV_ONTOLOGY = LabelledPetriNet([:Pop],
    :birth_t => (:Pop => (:Pop,:Pop)),  :pred_t  => ((:Pop,:Pop) => (:Pop,:Pop)),
    :death_t => (:Pop => ()),           :move_t  => (:Pop => :Pop))
```

- LV dynamics: one `@relation` UWD, 3 boxes (`birth_t`/`pred_t`/`death_t`), `oapply_typed`, then
  `add_reflexives(_, [[:move_t],[:move_t]], …)` so prey & predator can move. → 2 species, 5 trans.
- Geography: built mechanically from `grid_world(5)` — one `:Pop` junction per Tile, one
  `:move_t` box per directed Edge, then `add_reflexives(_, [[:birth_t,:pred_t,:death_t] ×25], …)`.
  → 25 species, 155 trans (80 move + 75 reflexive).
- `typed_product(lv, geo) |> dom`:
  - **species S = 50** = 2 × 25 ✅
  - **transitions T = 235** = 3·25 (local) + 2·80 (diffusion, both species per directed edge) ✅
  - result is a `LabelledPetriNet`; **names preserved as tuples** — `(:prey,:t1)`,
    `(:predator,:t1)`, `(:move_t,:mv2)`, … Full `(dynamics, location)` provenance, no positional
    guessing. This is the scaling property we required.

**Conclusion:** (C) holds. LV is defined once; world size lives entirely in the geography factor,
which is a mechanical image of the `TileWorld` ACSet.

### Implementation notes carried out of the spike

- **Index by name, never by position.** `typed_product` does NOT order species as
  `2(t-1)+1`; the spike showed `(:prey,:t1),(:predator,:t1),(:prey,:t6),…`. `sim.jl`/`viz.jl` must
  build a `name → state-index` map (e.g. `Dict(sname(net,i)=>i)`) rather than assume a layout.
  The current `viz.jl` positional indexing (`state[2*(tile-1)+1]`) is therefore **wrong** under
  stratification and must be replaced.
- The bespoke `LV_ONTOLOGY` is the type-system "vocabulary"; it (and where it lives / how it is
  versioned alongside the schema) is now a real artifact, not a sketch.

### Status / next action

- ✅ Precompiles; `grid_world` constructs `TileWorld`.
- ✅ Stratification substrate (C) validated end-to-end on 5×5 → 50 species, 235 transitions, named.
- ⛔ **Not yet done / unverified:**
  - Arc-level correctness of the composed net (that `(:move_t,:mvE)` really wires
    `prey@src → prey@tgt`, mass-action shapes intact) — confirmed only by counts so far; verify
    before trusting `simulate` output.
  - Rate assignment from tile/edge properties (`add_params` keyed by transition name/type).
  - Rewrite of `subsystems.jl` + `composition.jl` to (C); deletion of the dead labelled-open-net
    code; `viz.jl`/`sim.jl` switched to name-based indexing.
  - Update `simulation_laboratory_design.md` subsystem/composition layers to match (C).

---

## 2026-06-02 — First light: LV oscillations through the substrate

`scripts/run_mvp.jl` (rewritten to substrate C, self-contained) runs end-to-end on a 5×5 grid and
produces `scripts/lv_minimal.png`: clean sustained prey/predator oscillations with the correct
predator-lag, and a closed limit-cycle phase portrait. Pipeline:
`grid_world → typed LV (oapply_typed) → typed geography → typed_product → vectorfield → solve → plot`.

Two gotchas resolved getting here:
- **`vectorfield` indexes state by `sname`** (`AlgebraicPetri.jl:296,302`). For a *labelled* net
  that means an `LVector` keyed by names, not a positional `Vector`. Fix: simulate on
  `PetriNet(pn)` (labels stripped → integer indexing); build `u0`/`p` in that species/transition
  order, using the tuple names only to *decide* values.
- **`scripts/run_mvp.jl` was stale** — it called the dead `compose_world`, used positional state
  layout, and passed rates as a `NamedTuple`. Replaced wholesale.

Note: this is an arc-level functional check too — wrong wiring would not yield a clean LV cycle.
Still worth an explicit arc assertion before trusting heterogeneous (non-uniform) runs.

---

## 2026-06-02 — Refactor: process registry + agnostic geography (isolation as a config switch)

Pulled the hardcoded local UWD out into reusable package structure so that running a *subset* of
subsystems (isolation) or the whole thing (composition) is a one-line change. This is the
`CompositionConfig` idea from the design doc made real, and the groundwork for promoting a forcing
(moisture, weather) into a stock with its own sub-composition that can be tested alone or omitted.

Shape:
- `src/ontology.jl` — `ONTOLOGY` (the process vocabulary) lives here, on the dynamics axis, with
  `MOVE_TYPE` designated and `interaction_types()` = everything else.
- `src/subsystems.jl` — a `Process(name, type, species)` registry (`PROCESSES`) + bundles
  (`LV_PROCESSES`) + `assemble_local(process_names; mobile)` which builds the typed single-patch
  model from any subset and adds `:move_t` reflexives for the mobile species (indexed by the
  model's own species *names*, robust to oapply's ordering).
- `src/composition.jl` — `geography(world)` is now **ontology-agnostic**: every tile carries
  reflexives of *all* `interaction_types()`, so any local model stratifies onto it unchanged.
  `stratify(local, world)` returns the composed Petri net.
- `src/sim.jl` — rates keyed by **process** (`first(tname)`), state by **role** (`first(sname)`);
  `process_keys(net)` / `roles(net)` introspect the keys a net needs; simulate on `PetriNet(net)`.
- `scripts/run_mvp.jl` — thin; the process list is the only isolation/composition switch.

Why agnostic geography is safe: `typed_product` only emits a product transition when *both*
factors have a transition of a shared type, so geography reflexives with no local partner produce
nothing. Cost is a few unused parts in the geography factor, no spurious dynamics.

Verified:
- Full LV reproduces **identically** (50 species, 235 transitions, prey 372.5..2662.6) — refactor
  is behavior-preserving.
- Subset works: `assemble_local([:prey_birth]; mobile=[:prey])` on a 3×3 grid → 9 species, 33
  transitions, roles `[:prey]` only, simulates (pure growth). Same geography/stratify/simulate.

Still open: `viz.jl` remains positional/stale (exported with a warning comment) — rewrite to
name-based (`role_total`-style) when viz matters again. Arc-level assertion still not added.

---

## 2026-06-02 — Grass: first enrichment (registry-only), and the tri-trophic fragility

Added the grass layer. As predicted, it touched **only the process registry** — no ontology
change, no geography change. New processes (all reusing existing shapes):
- `grass_growth` (`:birth_t`)  grass -> 2 grass
- `grazing`      (`:pred_t`)   grass + prey -> 2 prey   (REPLACES prey's free birth)
- `prey_death`   (`:death_t`)  prey -> .                 (so prey has mortality off-predator)
Bundles: `GRASS_PREY = [grass_growth, grazing, prey_death]`,
`ECOSYSTEM = GRASS_PREY ++ [predation, predator_death]`.

Structural idea: push the LV "free birth / unlimited food" assumption down a level — grass is now
the unbounded primary producer, prey reproduces by grazing. Each level is born by consuming the
one below and dies by being consumed above; the chain is capped by grass (free birth) and predator
(natural death).

Ladder results (5×5 uniform world, `scripts/run_grass.jl` → `scripts/grass.png`):
- **Rung 2 (grass + prey):** *identical* to the original 2-species LV — grass 372.5..2662.6,
  prey 72.3..1631.8 (same numbers as prey/predator before). The tracer reappears one trophic
  level down, confirming the grazing wiring. Mathematically it *is* LV (grass=resource,
  prey=consumer with mortality).
- **Rung 3 (+ predator):** predator blooms once on the initial prey then **collapses to
  ~0** (effective extinction); grass + prey relax back into 2-level LV. No 3-level coexistence at
  these (arbitrary) rates.

Reading: exponential basal resource + tri-trophic LV is fragile — predator persistence needs the
time-averaged prey above `predator_death/predation`, which these rates don't meet. Two paths
forward: (a) tune predator rates to find a coexistence window (tri-trophic LV cycles exist but the
window can be narrow and the cycles large), or (b) add grass **carrying capacity** (logistic
self-limitation via a `grass + grass -> grass` crowding term) — which both stabilizes and widens
the coexistence window (Rosenzweig–MacArthur). (b) would be the **first genuinely new ontology
shape** (`2 -> 1`). Per the "let detail motivate the next increment" method, this collapse is the
motivation. Leaning: try a quick rate-tune first (cheap, no new structure), then add carrying
capacity if 3-level coexistence is too fragile/wild without it.

---

## 2026-06-02 — Carrying capacity: first new ontology shape, predator rescued

Climbed the intervention hierarchy from parameters → **ontology** (parameter sweeps couldn't
robustly rescue the predator with unbounded grass, so the wanted behavior wasn't reachable in the
old vocabulary). Added the **first genuinely new ontology shape**: `crowd_t` (`(Pop,Pop) → Pop`,
i.e. `2 → 1`). Because `interaction_types()` auto-includes it, the agnostic geography absorbed it
with zero changes. New process `grass_crowding` (`:crowd_t`, grass+grass→grass) gives grass
logistic self-limitation; new bundle `ECOSYSTEM_RM` = Rosenzweig–MacArthur tri-trophic chain.

K-sweep (`scripts/run_rm.jl` → `scripts/rm_sweep.png`, K = r/c, 5×5 grid):
- **Predator rescued at every K** — min predator never hits 0 (was 0.0 / extinct before). Carrying
  capacity fixed the collapse.
- **Coexistence is a STABLE POINT** (damped focus) at all K tried (20–600). Raising K raises the
  equilibria and weakens damping but does NOT produce a sustained limit cycle.
- Equilibria match closed-form RM: prey pinned at `P* = predator_death/predation = 250` total
  (K-independent); `G* = K/3` per tile (167/417/1250/5000 total); predator tracks grass
  (`Q* ≈ G*−5`). **The composed net reproducing hand-derived equilibria to the digit is the
  arc-level correctness check we'd deferred — the wiring is right.**

Instructive correction: predicted "raise K → limit cycles (paradox of enrichment)." Wrong with
**Type I (mass-action)** responses — RM is globally stable; K only rescales equilibria. The
sustained limit cycle / paradox of enrichment requires a **saturating Type II** response. So the
two levers are opposite: **carrying capacity stabilizes; Holling II destabilizes** — exactly the
field-guide nuance, now demonstrated in our own system. Natural next experiment: add Type II
grazing (state-dependent rate via `valueat`) to produce the oscillatory regime deliberately.

### Open questions

- Geography net from `TileWorld`: directed edges (current `world_gen.jl` emits both directions) →
  one movement transition per directed edge, or a symmetric movement type? Decide when building
  the geography factor; it must agree with how diffusion is typed.
- Heterogeneous *structure* later (e.g. ocean tiles with no flora): does stratification + rate
  masking suffice, or do we need per-tile UWDs (approach B) for those cases? Defer until a
  subsystem actually needs to be absent rather than zero-rated.
- Where does the type-system vocabulary live, and how is it versioned alongside the schema?

---

## 2026-06-03 — Phase-1 gating check: Decapodes co-resolves, but TetGen blocks on Windows

Ran the roadmap's Phase-1 prerequisite — does the field stack (`Decapodes`/`CombinatorialSpaces`)
coexist with the pinned population stack?
- **Resolve: clean.** Added `Decapodes 0.6.8`, `CombinatorialSpaces 0.10.0`, `DiagrammaticEquations
  0.2.6` with `Catlab 0.17.5` / `AlgebraicPetri 0.10.0` / `ACSets 0.2.28` **unchanged**. Fields and
  populations live in **one environment** — the biggest structural risk in Phase 1 is gone.
- **Precompile: blocked on Windows.** `TetGen_jll` `SIGABRT`s during `dlopen` (mingw-w64
  pseudo-relocation: `do_pseudo_reloc` / `_pei386_runtime_relocator`), on Julia 1.11.7 / Win11.
  `TetGen` is a **hard `[deps]`** of CombinatorialSpaces 0.10.0 (3D tet-meshing we don't need), so
  it can't be skipped. Platform/binary issue, not version resolution.
- **Populations unaffected:** `using SimLab` + `stratify` still work; the field deps are orthogonal.
- `Project.toml`/`Manifest.toml` backed up to `.bak`.

Decision pending (the field path's environment): **WSL2/Linux** (durable — JLLs reliable there;
the bug is Windows-specific) vs **Julia 1.10 LTS on Windows** (cheap long-shot; bug may be
1.11-specific) vs **park Decapodes, keep Petri-diffusion** for now. File an upstream bug regardless
(TetGen.jl/CombinatorialSpaces: Win + Julia 1.11.7 pseudo-reloc SIGABRT) — a real, small contribution.

**Update:** tested Julia **1.10.11 LTS** (downloaded portable, sealed temp env) — `TetGen_jll`
SIGABRTs *identically*. So the bug is **version-independent** (not a 1.11 loader quirk); it's the
TetGen_jll Windows binary. The 1.10 option is ruled out. Durable path = **WSL2/Linux**; interim =
Phase 2 (characterization) on Windows (needs no Decapodes). Full context + ready-to-file bug report
captured in `docs/handoff_decapodes_windows.md`.
