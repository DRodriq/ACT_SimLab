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

---

## 2026-06-06 — CombinatorialSpaces PR #230 (TetGen→weakdep): partial Windows unblock

`AlgebraicJulia/CombinatorialSpaces.jl` **PR #230** (merged 2026-06-05) — *"Move TetGen-backed 3D
meshing APIs into a package extension"* — does exactly what our bug-report draft asked: TetGen moves
from hard `[deps]` to a `[weakdeps]` extension (opt-in via `using TetGen`). Released as
**CombinatorialSpaces 0.10.1**.

Tested on this Windows machine:
- **`using CombinatorialSpaces` now loads cleanly** — the TetGen `SIGABRT` is gone (it's no longer
  loaded unconditionally). Decapodes 0.6.8 accepts 0.10.1 (patch-compatible).
- **But `using Decapodes` still crashes** — a *second*, unrelated native crash: precompiling
  Decapodes aborts at `canon/Physics.jl:8` where **DiagrammaticEquations** calls **utf8proc**
  (`utf8proc_decompose_custom` via a `@cfunction` thunk). Same Windows-C-callback smell as TetGen.
  The full Decapodes DSL still won't build on native Windows.

**Reframe (important):** Phase 1 doesn't need the Decapodes *DSL*. The mesh + DEC **Laplacian** live
in CombinatorialSpaces (now loading on Windows). So the roadmap's "hand-coupled RHS first" step —
`dg/dt = r·g(1−g/K) + D·Δg − grazing` on a CombinatorialSpaces mesh + DifferentialEquations — is
**doable on native Windows now**. The Decapodes-DSL "express it categorically" step (the crashing
part, already the time-boxed/optional half) is deferred to Linux/WSL.

Paths: (A) start Phase 1 on Windows via CombinatorialSpaces-direct; (B) Linux/WSL for the full
Decapodes DSL. File a second upstream bug (DiagrammaticEquations/utf8proc `@cfunction` crash on
Windows, Julia 1.11.7).

---

## 2026-06-06 (cont.) — Field path UNBLOCKED on Windows; DEC machinery validated

The `normalize_unicode` crash is the *same* bug the Linux session (2026-06-04) already nailed:
`Unicode.normalize(...; chartransform=julia_chartransform)` bakes a `@cfunction` into
DiagrammaticEquations' precompile image; invoking it from a downstream package's precompilation
crashes — **SIGSEGV on Linux, SIGABRT on Windows**, same crash site (`canon/Physics.jl:8`). Also
reproduced on **Julia 1.10.11 LTS** → version-independent (not a 1.11 package-image regression). Merged
bug report: `docs/upstream_bug_normalize_unicode.md`.

**Unblock confirmed on native Windows 1.11.7:**
- CombinatorialSpaces **0.10.1** (PR #230, TetGen→weakdep) loads — first wall gone.
- The `normalize_unicode` fix works both via the in-place patch script *and* via the user's fork
  `DRodriq/DiagrammaticEquations.jl#main`. **Decapodes precompiles + loads.**
- Wired the **fork** into the real `sim_lab` project (`add`-by-URL → baked into the Manifest, durable;
  the patch script is now a fallback). Project loads populations + fields together:
  `SimLab + Decapodes + CombinatorialSpaces on 1.11.7`. (Project/Manifest changes uncommitted.)

**Phase 1 — field machinery validated against analytic ground truth** (`scripts/field_kpp.jl`):
- Mesh: `EmbeddedDeltaSet1D` → `EmbeddedDeltaDualComplex1D` + `subdivide_duals!(Circumcenter())`;
  0-form Laplacian `Δ(0, sd)`. Sign: this `Δ` carries the continuum ∇² sign (negative at a peak),
  so diffusion is **+D·Δ**.
- **Step (a):** constant field → `max|Δ·const| = 1.1e-13`, boundaries exactly 0 → DEC Laplacian
  annihilates constants with **no boundary leak** (natural **Neumann/no-flux** BCs — exactly what the
  later "uniform reproduces RM" oracle needs).
- **Step (c):** Fisher–KPP front speed → analytic `2√(rD)`. Mesh-converged (N=201/401/801 all ≈1.764)
  and converges to 2.0 from below as the window moves later (1.73→1.91→1.95→1.96), the textbook
  **Bramson `~1/t` logarithmic correction** — not discretization error.

Next: the **coupling** — grass field ↔ Petri populations via grazing, with the mass-conjugacy
invariant gate and the uniform-reproduces-RM check (Phase 1, step 2).

---

## 2026-06-06 (cont.) — Phase 1 step 2: field↔population coupling VALIDATED

`scripts/field_couple.jl` — grass DEC field coupled to a prey population by grazing, hand-coupled
RHS over `[grass ; prey]`, integrated with `TRBDF2`.

**Formulation refinement (vs Step-0):** treat *both* grass and prey as **densities** on the mesh,
so grazing rates are area-free and the dual-cell volumes `A = diag(⋆₀)` enter only in the *mass
integrals* (`M = Σ Aᵢ·xᵢ`). Cleaner than Step-0's "prey-as-amount + ×A": it makes
uniform-stays-uniform automatic and mass-conjugacy structural. (`Σ Aᵢ = L = 20.0` confirms ⋆₀.)

Both validation gates pass to analytic precision:
- **Gate 1 — mass-conjugacy** (grazing only, spatially-varying IC): `M = Σ Aᵢ(gᵢ+pᵢ)` conserved,
  **rel. drift = 0.0**. Grass eaten == prey gained (ε=1). This is the decisive "real mass coupling
  vs plausible fake" test.
- **Gate 2 — uniform → equilibrium**: converges to closed form `g* = m_p/a = 2.0`,
  `p* = (r/a)(1−g*/K) = 1.2`, **rel.err = 0.0**, spatial spread `4e-15` (uniform stays uniform).

So the field↔population mass coupling — the load-bearing claim of v2 §3 — works on native Windows,
validated against ground truth. Phase 1's "hand-coupled RHS" is done and gated.

Remaining in Phase 1 (none blocking): spatial demonstration (perturb → grass front with prey
following — expect fronts, not stripes, single field); extend to full tri-trophic (predator is pure
Petri, no new coupling); and the time-boxed "express the coupling as a Decapode" (the DSL step).

---

## 2026-06-06 (cont.) — Phase 1 spatial demonstration: traveling grazing waves

`scripts/field_spatial.jl` → `scripts/field_spatial.png`. Uniform grass at `K` + a localized prey
pulse on a 1-D mesh (N=401, L=100). Result: two symmetric **constant-speed invasion fronts**
spreading outward from the seed — prey graze grass down to the coexistence level in the wake, which
relaxes to the validated equilibrium (`g*≈2`, `p*≈1.2`); grass-wake-min 1.28 is the front
overshoot. Space-time heatmaps show clean straight-edged "V" fronts. **Fronts, not stripes** — as
predicted, a single resource field + diffusing consumer gives invasion waves; Turing patterning
needs ≥2 differentially-diffusing fields. First genuinely spatial, emergent result of the project;
diffusion + the field↔population coupling working together.

**Phase 1 is complete and fully gated:** field machinery (KPP front, Neumann BCs) ✓, coupling
(mass-conjugacy, uniform→equilibrium) ✓, spatial behavior demonstrated ✓ — all on native Windows.

---

## 2026-06-06 (cont.) — Field expressed as a Decapode (DSL), full tri-trophic verified

`scripts/field_decapode.jl` — grass+prey+predator as one `@decapode` (all `Form0`; nonlinear form
products via broadcast `.*`/`.-`/`./` per the Gray–Scott idiom; constants scale with `*`), compiled
with `gensim`, run via `sim(sd, generate, DiagonalHodge())` + `ComponentArray` + `ODEProblem`.

Verified: uniform IC → closed-form tri-trophic equilibrium `G*=K(1−a·mq/(b·r))=2.5`, `P*=mq/b=1.0`,
`Q*=(a·G*−mp)/b=1.5`, **rel.err = 0.0**. The DSL reproduces the hand-coupled physics exactly.

Finding: **Decapodes `gensim` requires a 2-D mesh** — the generated `Δ` calls
`dec_p_dual_derivative(Val{1}, ::…1D)`, which is unimplemented for 1-D dual complexes. (The
hand-coupled path works in 1-D because it uses the `Δ(0,sd)` *matrix* directly.) So: 1-D for
matrix-level validation (KPP front etc.); **2-D `triangulated_grid` for the Decapode/DSL path.**
Promoted `ComponentArrays` to a direct dep (needed for the Decapodes state).

---

## 2026-06-06 (cont.) — 2-D spatial tri-trophic run on the Decapode

`scripts/field_decapode_spatial.jl` → `scripts/field_decapode_spatial.png`. 2-D `triangulated_grid`
(40×40), grass at `K` everywhere + a localized prey+predator seed; full grass↔prey↔predator
Decapode integrated with `Tsit5`. Emergent **target pattern**: an expanding prey **invasion ring**,
grass depleted in an expanding annulus (center regrowing toward `K` in the wake), and the **predator
following the prey with a spatial lag** (broad blob trailing in the interior). Final ranges: grass
0.39–5.0, prey 0–3.5, predator 0–1.07 — sensible tri-trophic spatial dynamics. First 2-D,
three-species spatial result, on the validated DSL machinery.

Gotcha: qualify `CairoMakie.Axis` — `ComponentArrays` also exports `Axis` (ambiguous in `Main`).
Plotting fields on the mesh: `mesh!(ax, s, color=field)` via the CombinatorialSpacesMakieExt (s is
the primal `EmbeddedDeltaSet2D`).

---

## 2026-06-06 (cont.) — Animated rendered sim (watch-it-evolve)

`scripts/field_anim.jl` → `scripts/field_anim.mp4` (+ `field_anim_frame.png`). MP4 of the 2-D
tri-trophic field (grass/prey/predator colored on the grid) evolving over t=0→24, 120 frames, via
`CairoMakie.record` (an `Observable` frame index driving `@lift`ed `mesh!` colors) — headless, no
display needed. Four prey+predator seeds → interacting grazing invasion waves with the predator
lagging in the wakes. The first watchable rendered sim. (Interactive live-window scrubbing would be
`GLMakie` — needs a display; run locally.)

---

## 2026-06-06 (cont.) — Interactive GLMakie dashboard (lab front-end v0)

`scripts/dashboard.jl` — first interactive front end. GLMakie added (0.13.11; co-resolves, no
downgrade; precompiles + loads headless). Dashboard: 5 parameter sliders (r, a, mₚ, b, m_q) + a Run
button (re-solves the 2-D tri-trophic Decapode on a ~20×20 grid), a channel menu (grass/prey/
predator), and a time slider to scrub; the chosen field renders colored on the grid.

`build_dashboard()` (construct-without-display) **verified headless** — Decapode compile, initial
solve, all widgets, observable wiring, `mesh!`, colorbar all construct cleanly. `launch_dashboard()`
opens the window — **pending live verification on a display** (run from the REPL:
`include("scripts/dashboard.jl"); launch_dashboard()`). Gotcha: qualify `GLMakie.Axis`
(ComponentArrays also exports `Axis`); set Axis `title` at construction (can't reassign the
Observable via dot-notation). Promoted GLMakie to a direct dep.

---

## 2026-06-06 (cont.) — Discrete-grid visualization (the representation-matched view)

Decision: the simulation space is, at its core, a **discrete grid**, so visualize it discretely.
`scripts/grid_anim.jl` → `outputs/grid_anim.mp4` (+ frame). The stratified Petri tile-graph
(`ECOSYSTEM_RM` over `grid_world(12)`, 432 species) with prey/predator seeded in central tiles,
rendered as a **per-cell `heatmap`** (cell-based → one flat color per tile, NO interpolation —
honest to the discrete substrate, unlike the interpolated `mesh!` field view). Prey spread tile-to-
tile via `move_t`, predator fills the wake, grass depletes at the front. 144-tile `typed_product`
built fine and fast.

Principle established: **match the visualization to the representation** — discrete tile model →
per-cell blocks; continuum field → smooth/interpolated. Now have both; they're the two-
representations-two-visualizations pairing. (Tuning for a crisper discrete front: lower `move_t`,
bigger grid, smaller seed.) Outputs now live in `outputs/`.

---

## 2026-06-07 — Compositional subsystem gallery (Phase 1: configs + trendline preview)

Building a viz that matches the substrate philosophy: view/simulate subsystems in *isolation* and in
*composition*. `scripts/gallery.jl`. Key conceptual move (the user's insight): **isolating a
subsystem = cutting its lower coupling and stubbing it with a forcing.** "prey + predator, no grass"
stubs prey's food with `prey_birth` (unlimited-food constant) → that *is* classic LV. So a config =
a closed process set + its stubs.

Config library (discrete Petri rep, shared global `RATES` for fair comparison): `grass`, `grass+prey`,
`prey+predator` (LV via `prey_birth` stub), `full (RM)`. Reusable infra: `Sys`, `build_sys`,
`run_sys`, `role_grid/role_total`.

Phase-1 verified (`outputs/gallery_preview.png`): all 4 build + run, no blowups. The trendline gallery
(species totals vs time, shared current-frame line) reveals a principle *by comparison* —
**grass-alone flat at K; grass+prey & full damp to coexistence; LV cycles forever** — making visible
that the **carrying capacity is the stabilizer** (LV lacks it → neutral cycles). Decisions: D1 explicit
stubs, D2 gallery, D3 shared params, D4 uniform grass-alone. Layout: trendline gallery + one selectable
spatial grid. Next: Phase 2 (config-driven render) → Phase 3 (interactive GLMakie gallery).

**Phase 3 (interactive gallery) built + layout-verified.** `scripts/gallery.jl` → `launch_gallery()`.
Four trendline panels (one per config, shared current-frame line) + 9 global sliders (shared params,
T, frames) + config/channel menus + Run + the selected config's species on the discrete grid
(per-cell heatmap). All four nets built once at load; Run re-solves all configs together with shared
params. `build_gallery()` headless-verified; full layout verified via CairoMakie static render
(`outputs/gallery_full_preview.png`). Live GLMakie interactivity pending user verification.
Verification trick worth keeping: render a GLMakie dashboard's `Figure` statically with
`CairoMakie.activate!()` + `save(...)` to check layout/content headlessly before the live run.

---

## 2026-06-07 — New primitive class: conserved-currency flow (predation as biomass accounting)

`scripts/biomass_lv.jl`. The `predator + prey → 2 predator` token-rewrite has no ledger, so 100%
conversion (`ε=1`) is baked in → predators can outweigh prey. New primitive: predation as a **biomass
FLOW** — biomass leaves prey, `ε` enters predator (Lindeman ~0.1), `(1−ε)` dissipates to a sink;
plus a cumulative source-draw. Stocks {P, Q, D(sink), S(source)}.

**Forcing/emergent discipline (the user's frame):** forcings = unlimited food source, `ε`, rates;
emergent = stocks, the pyramid `Q/P`, equilibria. The pyramid is *not imposed*. Through-line to the
gallery: a forcing in isolation (unlimited food) becomes an emergent coupling under composition
(grass stock) — stub→coupling and forcing→emergent are the same move.

Both gates pass: **conservation rel-drift ~1e-14** (machine precision); **pyramid emerges** — `ε=0.1`
→ `Q/P=0.121` (predator ~8× below prey), matching closed form `εα/γ` to 3 digits (vs `ε=1` → 1.28).
`outputs/biomass_lv.png`. Concept validated hand-rolled; next: full conserved trophic chain
(sun→grass→prey→predator→detritus, Lindeman per link) then lift to `StockFlow.jl` (composable
AlgebraicJulia stock-flow primitive). Later: body-mass/maintenance (Kleiber) where the metabolic
scaling laws attach.

---

## 2026-06-07 — Food-web-as-DATA + functorial generator (conserved trophic chain)

`scripts/foodweb_chain.jl`. Architecture for arbitrary modular food webs: the web is **data**
(`Species` nodes + `Feed` edges, each carrying ε/rate), the dynamics are **generated** by a single
function that never names a species. `sun → grass → sheep → wolf → detritus`, every feed a conserved
biomass flow (ε in, 1−ε to detritus), producers logistic from a solar forcing, maintenance →
detritus. **Detritus = accumulating sink, deliberately NOT fed back** — closing the loop needs an
energy(one-way)/matter(cyclic) currency split; tracked now, wired later.

Gates: conservation rel-drift **1e-12**; all three levels persist. Finding worth keeping:
grass 25 ≫ sheep 2.5 ≈ wolf 2.0 — the top two near-equal. Not a bug: every *flow* obeys Lindeman
(ε=0.1/link), but **standing biomass = flow × residence time** (Little's law); wolf's ~10× longer
residence (low maintenance) cancels its 10% throughput → wolf ≈ sheep. The "biomass pyramids needn't
match energy pyramids" point, demonstrated unforced from conserved flows. Modularity proven: web is
5 data rows; add species/edge = add a row, generator unchanged. Next options: branch the web
(modularity demo), lift to Catlab ACSet + AlgebraicPetri/`StockFlow.jl`, or add a nutrient currency
to close the detritus loop.

**Branched the web → intraguild predation (fox).** `scripts/foodweb_fox.jl` — *same generator*, fox
added as data (eats sheep, eaten by wolf; wolf eats both → IGP: wolf IG-predator, fox IG-prey, sheep
shared resource). With symmetric params, **fox is excluded** (extinct by t≈75) and the system reverts
*exactly* to the grass→sheep→wolf chain (25/2.5/2.0) — the IGP module collapsing to its sub-chain.
Reproduces Holt & Polis 1997: IGP coexistence requires the IG-prey to be the *superior resource
competitor*; symmetric → IG-predator wins. Conservation held through the extinction (1.4e-12).
3-species community modules (food chain / apparent competition / exploitative competition / IGP) are
the composable building blocks — our web-as-data makes "compose a module" literal. Coexistence lever:
make fox the better sheep-competitor (raise `sheep→fox` rate / lower fox maintenance).

**The "coexistence flip" is actually a competitive role-reversal (a better finding).**
`scripts/foodweb_igp_flip.jl` + sweeps. Raising `sheep→fox` doesn't *add* fox to a 4-species web —
it flips *which predator survives*, at a **sharp threshold ≈0.65** (no coexistence band): below →
wolf wins (fox excluded, grass→sheep→wolf); above → fox wins (wolf excluded, grass→sheep→fox).
Winner-take-all competitive exclusion (Gause) mediated by IGP; three-way coexistence is the
knife-edge Holt–Polis describe. Trophic-cascade signature differs by regime: fox-wins releases grass
(42 vs 25), suppresses sheep (0.75 vs 2.5). A clean generative effect — the composition's outcome
(who wins, bistable across a threshold) is in none of the parts.

Wrote `docs/community_modules.md` — formal treatment of community modules (food chain / exploitative
competition / apparent competition / IGP) as composable building blocks, mapped to the substrate
(module = sub-web data; composition = gluing along shared species; conserved currency keeps modules
honest; validate-then-compose), tying modules→webs to `compositionality.md`'s structure-composes /
behavior-emerges. Extended `dynamics_field_guide.md` §2 with the four modules + reverse-lookup rows
(winner-take-all switch → IGP; top predator raises base → cascade).

---

## 2026-06-08 — Two-currency engine: Energy (open) + Nutrient (closed)

`scripts/two_currency.jl` (Stage 1). Motivated by the carcass discussion: detritus isn't a uniform
sink, and closing the loop needs the energy/matter split. Clean framing: **matter = limiting NUTRIENT
(not carbon), so respiration removes ENERGY ONLY** (you don't respire away your nitrogen). Minimal
cast: mineral · grass(E,N) · detritus(E,N) · fungus/decomposer(E,N); loop mineral→grass→detritus→
fungus→mineral.

Two conservation gates, both **~1e-16**: **energy open** (`Solar = stored + Heat`, one-way sun→heat —
plot shows in/out climbing together, biomass a thin sliver) and **nutrient closed** (total invariant,
just cycling). The prize: **`E/N` quality is a real emergent value, declining monotonically along the
detrital path** — grass 2.5 → detritus 2.09 → fungus 0.86 → **mineral 0** (food → fertilizer), a new
emergent *niche axis* with the decomposer occupying it. Gotchas en route: (1) energy-drift metric must
subtract the initial stored energy (invariant = `stored+Heat−Solar` = initial stored, not 0); (2)
mineralization must come from the *decomposer* excreting excess nutrient (energy-limited on N-rich
detritus), not from detritus directly, else the decomposer hoards all nutrient; (3) decomposer must
respire energy *through* to heat (high `rf`) or the gradient inverts. Next — Stage 2: animals (sheep/
fox/wolf) + carcass cast-off (predator-specific utilization) + **general scavenging** (carcass→fox
AND wolf AND fungus) + stoichiometric (Liebig) feeding. Full green+brown web on two currencies.

**Stage 2 — full green+brown two-currency web.** `scripts/two_currency_web.jl`. 8 pools (mineral,
grass, sheep, fox, wolf, carcass, SOM, fungus), each (E,N). Stoichiometric `assimilate!`: ingested
E,N → growth at body ratio (Liebig min), excess N→mineral, excess E→heat, egesta→SOM — conserves
both currencies by construction. Predation casts off un-utilized kill → carcass (fox messy/util 0.4,
wolf clean/util 0.8); carcass scavenged by both fox & wolf, ages→SOM; fungus decomposes SOM,
mineralizes via stoichiometric excess.

Mechanism rock-solid: **both gates machine-precision (N ~1e-14, E ~1e-15) in every config**, incl.
total collapse. Emergent findings (unforced): (1) **nutrient immobilization** — decomposer/SOM holds
~85% of nutrient *stock* (realistic; here flux-limits the green web); (2) **the decomposer is
load-bearing** — too-high fungus turnover → no mineralization → producers starve → *whole-system
extinction*; (3) **scavenging aids the IG-predator (wolf 0.16→0.23) not the IG-prey (fox stays
excluded)** — the shared carcass eases but doesn't break IGP exclusion; (4) emergent carcass quality
`E/N≈0.58`. The balanced-coexistence regime is a *narrow window* (fungus-hoards ↔ fungus-dies) —
a parameter-space exploration job, not hand-tuning. Gotcha: decomposer only mineralizes when
*energy-limited*, so SOM must lose energy as it ages (`rso`) or nutrient locks up.

---

## 2026-06-08 — The harness core: currency-AGNOSTIC engine + Scenario as the single forcing layer

`scripts/harness.jl`. The "harness is the product" inflection. Reframe: the engine is now invariant;
*everything that varies is a forcing*, and the harness is the complete, uniform surface of forcings,
organized as an **intervention ladder** — L1 parameters (sweep), L2 structure (toggle species/edges),
L3 vocabulary (extend currencies/primitives). "Adding a fox" = asserting a bundle of forcings (role +
body composition + rates) + typed edges; its behavior is emergent. Structural change and parameter
tweak are the *same operation* (varying the Scenario).

Decision (user): **currency-agnostic** engine — over-abstract the engine where it pays. One rule —
**Liebig-limited growth over K currencies** — with `K=1`/`K=2` as instances. Currency topology: closed
→ excess recycles to an available pool (conserved); open → dissipates to a terminal sink + exogenous
source. `Scenario` = {currencies, pools (name/role/comp/maint/mort/crowd/src), feeds
(res/cons/rate/util/assim), detritus, init, avail0} — the single declarative layer.

Validated both ways: **[A] K=2 conservation** machine-precision (nutrient 3e-15, energy 5e-16);
**[B] K=1 reproduces the IGP role-reversal** (sheep→fox 0.2→wolf wins, 0.8→fox wins) — *same engine*,
one-currency Scenario. Our hand-rolled scripts were informal Scenarios; this formalizes + unifies
them. Next: `classify(sol)→regime` + `sweep(scenario, axes)→regime map` (the characterization
artifact; the Stage-2 2-D regime map becomes a one-liner). Then port to `src/`.

**`classify` + `sweep` + the first regime map.** `scripts/harness.jl` (core, includable) now has
`classify(sol)→(surviving, regime, conserved)` and `sweep2(base, ax1, ax2)` (each axis = label +
values + setter; `set_pool`/`set_feed` rebuild the immutable Scenario). Added a `decay` field on dead
pools (open-currency stripping). `scripts/regime_map.jl` re-validates (A,B still pass) then sweeps.
First attempt — K=2 web — was a *dud*: the green web is nutrient-starved everywhere (sheep excluded in
all 272 cells), the immobilization pathology again; a bad first figure. Pivoted to the **K=1 IGP**
(known rich structure) → **`outputs/regime_map.png`**, our own **Holt–Polis phase diagram** (299
conserved runs): wolf-wins | fox-wins separated by the role-reversal boundary, the boundary **tilts
with productivity** (high productivity favors the IG-predator — the central Holt–Polis result,
emergent), and a **3-cell coexistence sliver on the boundary** (the knife-edge). The full pipeline
works: Scenario → generate → classify → sweep → figure. Today's hand-tuning struggle is now a function
call.

**Ported to `src/`.** `src/harness.jl` is now a `module Harness` inside the package (`run`→`run_scenario`
to avoid the `Base.run` clash), included + re-exported by `SimLab.jl`. `using SimLab` exposes
`Currency, Pool, Feed, Scenario, run_scenario, classify, sweep2, set_pool, set_feed, drifts, ssize,
ssize_end`. `scripts/regime_map.jl` now consumes it via `using SimLab` (no local include); full
integration test passes (package precompiles; validations + the 299-run map reproduce identically).
The harness is real package infrastructure — the engine is fixed and small, the Scenario+sweep+classify
lab is the product.

---

## 2026-06-08 — Repo reorganization: the repo mirrors the software (experiments/ + tools/)

Scaffolding for the isomorphism *repo ↔ software*: engine fixed (`src/`), everything that varies is a
forcing made physical. New layout: **`experiments/`** (each subdir = a `Scenario` + `run.jl` + a
README + **co-located `outputs/`**; an experiment dir ↔ a Scenario instance), **`tools/`** (interactive
instruments — dashboards/viz, readers of the harness), `src/` (engine+harness), `docs/` (thinking).
`README.md` augmented with the layout + how-to-run; `experiments/README.md` is the index; `_template/`
the skeleton; structured agent-readable README schema (Question/Scenario/Run+Gate/Result/Notes).
Experiments double as the regression suite (each carries a gate). First experiment migrated:
`experiments/igp-phase-diagram/` (from `scripts/regime_map.jl`) — runs from its home, co-located
output, gate passes (299 runs conserved). Next: triage `scripts/` (rebuild population/currency ones as
harness experiments + demos; keep field/Decapodes as a separate-engine track; dashboards→tools;
delete scratch) — pending sign-off. Note: two distinct engines now (K-currency population harness vs
DEC field); only harness experiments are Scenarios.

**Triage executed.** `scripts/` and the global `outputs/` are gone; top level is now
`docs/ experiments/ src/ tools/`. **Rebuilt as live, gated harness experiments:** `lv-two-species`
(neutral cycle), `trophic-chain` (grass 25/sheep 2.5/wolf 2, residence-time pyramid),
`biomass-pyramid` (ε sweep: pred/prey 0.12→1.15), plus `igp-phase-diagram` (already). **Migrated
(code preserved, other engines):** `field-coupling` + `field-tritrophic` (Decapodes), `discrete-grid`
(Petri). **Planned (README only, rebuild next):** `grass-prey-predator`, `two-currency-engine`,
`two-currency-web`. **Tools:** `dashboard`, `gallery` → `tools/`. **Deleted:** 10 superseded/scratch
scripts (recoverable from git). Each experiment carries its own README (Question/Scenario/Run+Gate/
Result/Notes) and co-located `outputs/`; outputs are 1:1 with experiments. Package still loads; the
three rebuilds' gates pass.
