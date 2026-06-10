# Substrate — one composition discipline, several subsystem types

> **Re-grounded.** An earlier version of this doc declared "the lab runs on more than one engine" and
> named a hand-rolled harness "the primary engine." That was **drift** (see `drift_diagnosis.md`).
> The intent — and the hard requirement — is **one categorical composition discipline** into which
> different subsystem *types* are added as categorical citizens. Read `status.md` first.

The goal is *not* multiple engines; it is one discipline (functorial composition on Catlab/AlgebraicJulia,
Catlab 0.17.5) in which populations, fields, currencies, and later agents are all "the same kind of
arrow" and compose as one system (v2 §3). Below: the subsystem types, and which are categorical today
vs. being realigned.

## Subsystem types

### Populations — typed Petri (categorical) ✅
Typed mass-action Petri nets (AlgebraicPetri). Processes typed into an `ONTOLOGY`; `assemble_local`
builds a single-patch model; **`stratify` distributes it across a grid via `typed_product` with `move_t`
diffusion** — this is how spatial population dynamics is *supposed* to be done. `src/{ontology,subsystems,
composition,sim}.jl`. Experiments: `discrete-grid`.

### Fields — Decapodes / DEC (categorical) ✅
Continuous reaction–diffusion PDEs on a mesh (Decapodes / CombinatorialSpaces). The `Δ` Laplacian;
structure-preserving discretization with conservation gates. Genuinely continuous space (a mesh, not a
tile graph). Experiments: `field-coupling`, `field-tritrophic`.

### Currencies — being realigned ⛳
Conserved multi-currency dynamics (energy + nutrient, Lindeman ε, Liebig limitation) is a **real gap**:
mass-action Petri has no ledger, so ε=1 is structural. The current implementation is a **hand-rolled,
non-categorical ODE engine** inside the harness (`generate`, the `Pool`/`Feed` vocabulary) — the drift.
**Being realigned** into a categorical subsystem type on Catlab 0.17 (a currency-bearing ACSet + a
dynamics functor over AlgebraicPetri's composition machinery). Off-the-shelf `StockFlow` /
`AlgebraicDynamics` are version-blocked (no Catlab 0.17 release), so this is frontier extension, not
adoption — the gap *is* the work.

### Agents — planned
`Para(Optic)` / Structured Active Inference: a subsystem with a non-trivial backward (selection) pass.
Same substrate as the world (v2 §5). Not built.

## The characterization tier (sits on top, type-agnostic)

`Scenario` (forcings) → `sweep2` (regime maps) → `classify` — the measurement/characterization layer.
This half was always the right idea; it rides on top of whatever the subsystem types are, unchanged.

## Status table

| subsystem type | tool | spatial | categorical today? |
|---|---|---|---|
| populations | typed Petri / AlgebraicPetri | grid via `typed_product` | **yes** |
| fields | Decapodes (DEC) | continuous mesh | **yes** |
| currencies | (hand-rolled ODE) → currency ACSet | (revert hand-roll → stratification) | **being realigned** |
| agents | Para(Optic) | (tbd) | planned |

The endpoint: all of these compose by **one** discipline. Each experiment's README states which
subsystem type(s) it uses.
