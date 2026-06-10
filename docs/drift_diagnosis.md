# ACT_SimLab — Architectural Drift Diagnosis

**Date:** 2026-06-08
**Repo:** `git@github.com:DRodriq/ACT_SimLab.git` @ `e196b7a` ("updated readme", 2026-06-08)
**Author of note:** research subagent, with Dane
**Scope:** Diagnose the gap between the *intended* architecture (design docs + Dane's stated
intent) and the *as-built / as-documented* state (the code and the builder agent's `engines.md`).

---

## TL;DR

The intended design is **one expandable categorical engine** with a **thin harness** on top for
forcings/sweeps (input side) and characterization (output side), so experiments ride on top without
touching internals and verifiability/composition stay categorical. Both design docs say exactly
this; Dane's recollection is faithful to them.

The repo has drifted: the **harness became a second, hand-rolled, non-categorical simulation
engine** that does the actual flagship work, and the categorical (Petri) engine is sidelined to one
experiment. The builder agent's `engines.md` then **enshrined the drift as doctrine** — declaring
"the lab runs on more than one engine," naming the harness "the primary engine," and (via a
not-yet-built `run_spatial`) planning to give the harness its own hand-rolled spatial diffusion,
which would make the categorical engine fully vestigial.

The drift is **a near-perfect catalog of the anti-patterns design-doc v2 was written to forbid**
("stop hand-rolling the composition substrate"; "default to adopting; justify any hand-roll";
"don't approximate diffusion with Petri edges if a field is meant"; "the recurring failure mode is
rebuilding 2021 by hand").

Crucially: the drift is **localized**. The harness's characterization half (`Scenario` forcings +
`sweep2` + `classify`) *is* the tier the design wants. Only its simulation half (`generate`, the
hand-coded RHS, and the parallel `Pool`/`Feed` vocabulary) overstepped. Realignment is to make
`generate` delegate to an adopted categorical substrate, not a rewrite of the harness.

---

## 1. The intended design (grounded in the docs)

### v1 — `docs/simulation_laboratory_design.md`

Six-layer pipeline, each arrow a stable interface:

```
Schema (Catlab) → World-gen (ACSet) → Subsystem (AlgebraicPetri OpenPetriNet)
→ Composition (oapply / structured cospans) → Simulation (AlgebraicDynamics + DiffEq)
→ Harness
```

The harness is explicitly **instrumentation, not an engine**:

> "**The harness is the product.** Instrumentation, characterization, scenario management, and
> diagnostic loops are first-class. The simulation engine is comparatively small; the laboratory
> around it is most of the work."

Harness layer contents: `ParameterStore | TimeSeriesCapture | ScenarioRunner | SweepRunner |
Characterization | Diagnostic | Visualization | AI-assist`. **No simulation.**

v1's `Scenario` is a **config bundle that selects categorical subsystems + params** —
`(schema_version, world_gen_config, composition_config, parameter_snapshot, initial_state,
duration, capture_config)` — NOT a description of pools/feeds/currencies.

v1 names the exact payoff Dane remembers:

> "Subsystem isolation is a config change, not a code branch. This is the load-bearing payoff of
> the categorical structure."

### v2 — `docs/simulation_laboratory_design_v2.md`

A re-foundation whose single thesis is **adopt the frontier substrate; spend originality on
characterization**:

> §1: "**Stop hand-rolling the composition substrate.** … adopt the frontier substrate wholesale,
> and spend your own research energy on the layer the field has under-built."

> §9 (anti-reinvention): "The recurring failure mode is **rebuilding 2021 by hand**." → "Don't
> re-derive oapply-to-ODE" (use `AlgebraicDynamics`); "**don't approximate diffusion with Petri
> edges if a field is meant**" (use `Decapodes`); "**Default to adopting; justify any hand-roll.**"

> Risk: "**The reinvention reflex.** §9 exists because the strongest pull is to rebuild what the
> frontier already ships."

And v2 is explicit that heterogeneous formalisms is **one composition discipline, not many
engines**:

> §3: fields (Decapodes) / populations (Petri) / agents (Para(Optic)) are different subsystem
> *types* that **compose as one system**; "DCST is the vocabulary in which 'all the same kind of
> arrow' is literally true."

**Conclusion:** the written design = one categorical engine + thin instrumentation harness +
adopt-don't-hand-roll. This matches Dane's stated intent exactly.

---

## 2. The as-built / as-documented state

### Code reality (`e196b7a`)

- `src/harness.jl` (~150 lines) imports **only `DifferentialEquations`**. Zero Catlab / AlgebraicPetri
  / `oapply` / `typed_product`. It hand-writes the ODE RHS in `generate` (harness.jl:42–93).
- All four flagship experiments (`igp-phase-diagram`, `biomass-pyramid`, `trophic-chain`,
  `lv-two-species`) use only `Scenario` / `run_scenario` / `sweep2` — i.e. the harness engine.
- The categorical (Petri) stack (`ontology` / `subsystems` / `composition` / `sim`) is used by
  exactly one experiment, `discrete-grid`.
- The harness invented a **parallel system-description vocabulary** — `Pool` / `Feed` / `Currency` —
  next to the engine's `Process` / `PROCESSES` / `assemble_local`. Two ways to say "predator eats
  prey."

### The builder's doctrine (`engines.md`, dropped in workspace by Dane)

- Opens: "**The lab runs on more than one engine** … distinct dynamical substrates … *different
  formalisms*."
- Labels the harness "**the primary engine**."
- Describes a `run_spatial(scn, N, mobile)` (replicate Scenario over an N×N grid, diffuse mobile
  pools via a graph Laplacian) and a `spatial-foodweb` experiment.

### Doc-vs-code drift (verified)

- `grep run_spatial` over the repo → **not found**. `harness.jl` has no spatial/Laplacian/grid/
  diffuse code at all.
- `experiments/spatial-foodweb/` → **does not exist**.
- The doc's harness experiment list also omits `two-currency-engine` / `two-currency-web`, which do
  exist as dirs.

So `engines.md` describes a harness **bigger than the committed one** — partly aspirational/imagined
relative to `e196b7a`.

---

## 3. Three layers of drift

1. **Design → code.** Harness became the de-facto simulation engine (intended: thin waist over one
   categorical engine). The categorical core was sidelined.

2. **Code → doc.** `engines.md` documents capabilities not in the repo (`run_spatial`, the
   graph-Laplacian spatial harness, `spatial-foodweb`). The builder is documenting intent as fact.

3. **Doctrine.** `engines.md` enshrines the drifted state as the architecture — "more than one
   engine" as a feature, harness "primary," categorical engine demoted to "the original substrate"
   kept for niche use. This is the *inversion* of both design docs (one composition discipline).

**Trajectory tell:** the categorical engine's last unique justification was *spatial composition*
(`typed_product` / `move_t`). The phantom `run_spatial` shows the builder's next move is to give the
harness its own hand-rolled diffusion — which would make the categorical engine entirely vestigial,
and is *literally* v2 §9's named anti-pattern ("don't approximate diffusion … if a field is meant").
The drift is accelerating away from the design, not correcting.

---

## 4. Design-intent vs as-built (summary table)

| dimension | design (v1 + v2) | as-built / `engines.md` |
|---|---|---|
| number of engines | **one** composition discipline | "more than one engine," stated as a feature |
| harness role | instrumentation / sweep / characterization tier *on top* | "the primary engine" — hand-rolled ODE simulator |
| `Scenario` | config bundle selecting categorical subsystems + params | hand-written pools/feeds/currencies → hand-coded RHS |
| subsystem vocabulary | `Process` typed into `ONTOLOGY` | forked: `Pool`/`Feed` parallel to `Process` |
| isolation / composition | functorial — "config change, not a code branch" | "write a smaller struct"; no functorial guarantee |
| how subsystems relate | all "the same kind of arrow," they **compose** | engines don't compose with each other at all |
| hand-rolling | "default to adopting; justify any hand-roll" | hand-rolled engine + currencies; diffusion next |
| spatial | categorical (`typed_product`) or Decapodes fields | being re-homed into the harness (`run_spatial`) |
| conserved currencies | the open problem to solve *categorically* (StockFlow) | already hand-rolled, off the categorical path |

---

## 5. Why it drifted (the licensing seed)

The drift has a seed inside v1's own pragmatism watch-points: "the simulation engine is comparatively
small"; "**Ugly working code beats elegant non-running code**"; "Milestone 0 in days, not weeks." A
builder optimizing for fast, gated, working code could read that as license to hand-roll the engine
and pour effort into the harness.

**v2 explicitly closed that door** ("justify any hand-roll"; "default to adopting") — but the journal
shows the builder worked off v1's pragmatism and **never executed v2's adoption mandate**. The only
nod toward a frontier currency substrate is "lift to `StockFlow.jl`," repeatedly *deferred*
(journal 2026-06-07, 06-08). Net: the builder kept the design's **destination** ("harness is the
product," "characterization is the research") and reversed its **means** ("adopt the substrate" →
"hand-roll a primary engine").

---

## 6. The decision point that forked it

Single journal entry: **2026-06-07, "conserved-currency flow."** The categorical engine's mass-action
token-rewrite (`predator + prey → 2 predator`) **has no ledger** — ε=1 is structurally baked in. The
project needed conserved multi-currency accounting (energy + nutrient, Lindeman ε, Liebig limitation),
which plain `LabelledPetriNet` cannot express. Two options at the fork:

- **(A)** extend the categorical engine to carry currencies (StockFlow.jl / currency-bearing ACSet),
  keeping everything categorical and the harness thin — *the v2 mandate*.
- **(B)** hand-roll conserved dynamics in `generate` — fast, gated, works.

The repo took **(B)**. It worked and produced all the good figures — and it is the precise decision
that turned the harness from a waist into an engine and sidelined the categorical core.

---

## 7. Empirical finding — the two engines are *consistent* (so the fork is recoverable)

To test whether the two disjoint engines at least agree, we extracted each engine's RHS from its own
code and integrated both with identical solver/tolerance/sampling. (Scripts:
`workspace/compare_engines.jl`, `workspace/control_epsilon.jl`; Julia 1.11.7, repo Manifest.)

**Shared case — identical mass-action LV** (`dN/dt = rN − aNP`, `dP/dt = aNP − mP`), harness Feed set
to ε=1 (`util=assim=1`) to match the Petri token-rewrite's baked-in ε=1:

| metric | result |
|---|---|
| max \|Δprey\|, max \|Δpred\| | ~3–4 × 10⁻¹⁰ |
| **relative Δ** | **8.6 × 10⁻¹¹** (solver tolerance) |

→ The engines compute the **same dynamics** on shared ground.

**Negative control — harness Feed at its real ε=0.5** (ledger on); Petri is structurally always ε=1:

| harness ε | max \|Δpred\| vs Petri | final pred (Petri / harness) | biomass drift |
|---|---|---|---|
| 1.0 | **0.0** (exact) | 3.58 / 3.58 | 2e-15 |
| 0.5 | **4.42** (diverges) | 3.58 / **0.41** | 9e-16 |

→ At ε<1 they diverge **exactly** as the conserved-currency ledger predicts (predator gains ε of the
kill; the rest → detritus), and the harness still conserves total biomass to machine precision. The
divergence *is* journal-entry 2026-06-07 executed: "the token-rewrite has no ledger, so ε=1 is baked
in."

**Interpretation:** the two engines are mutually **consistent, not contradictory** — two correct
implementations that coincide exactly where their expressiveness overlaps, and differ exactly by the
conserved-currency ledger the Petri net lacks. Consistency was established *by running them*, not
guaranteed *by construction*. A categorical currency substrate (StockFlow) would make this kind of
agreement structural rather than coincidental.

---

## 8. Realignment direction (not a plan — a pointer)

The realignment is **one function deep**, because the harness's characterization half is already the
right tier:

> Make `generate` compile a `Scenario` **into a categorical model** (extended to carry currencies —
> `StockFlow.jl`, or a currency-bearing ACSet over an extended `ONTOLOGY`) **instead of into a
> hand-written RHS**, and unify `Pool`/`Feed` with `Process`/`PROCESSES`. Then `sweep2` / `classify` /
> the experiments sit unchanged on top, and the engine is once again **one categorical thing** — the
> place new behaviors and categorical concepts get added.

The one real, answerable obstacle: **can `StockFlow.jl` (or a minimal currency extension of the
existing typed-Petri path) actually express the harness's one rule — Liebig-limited growth over K
conserved currencies with open/closed topology?** If yes, realignment is real and the harness
collapses back to the intended waist. If no, the hand-rolled fork was load-bearing and the design
needs an honest amendment. **This assessment is the recommended next step.**

---

## 9. Provenance / artifacts

- Repo clone: `workspace/ACT_SimLab/` @ `e196b7a`.
- Builder doc under analysis: `workspace/engines.md`.
- Design docs: `ACT_SimLab/docs/simulation_laboratory_design.md` (v1),
  `.../simulation_laboratory_design_v2.md` (v2).
- Decision narrative: `ACT_SimLab/docs/journal.md` (esp. 2026-06-02 substrate decision; 2026-06-07
  conserved-currency; 2026-06-08 "harness is the product" + repo reorg).
- Consistency check scripts: `workspace/compare_engines.jl`, `workspace/control_epsilon.jl`
  (one-off; delete after this note is durable per the no-one-off-scripts convention).