# ACT_SimLab

A **compositional simulation laboratory** built in the [AlgebraicJulia](https://www.algebraicjulia.org/)
ecosystem. It uses a deliberately minimal **Lotka–Volterra / Rosenzweig–MacArthur** ecology as a
*known-ground-truth testbed* for exercising and pushing the categorical-systems frontier — typed
Petri nets and stratification, continuous (Decapodes) fields, and `Para(Optic)` agents — and for
treating the **characterization of emergence** as the research contribution.

> **Status:** research work-in-progress. The population substrate is validated end-to-end against
> closed-form solutions; the spatial-field path is designed and scoped (see *Roadmap*).

---

## The idea

Composition is functorial — you can *assemble* open systems lawfully and at scale. But **behavior
emerges**: the qualitative dynamics of a composite are not a simple function of its parts'. The
categorical machinery makes the *structure* rigorous so that the *emergence* can be studied honestly.
(See [`docs/compositionality.md`](docs/compositionality.md).)

Two commitments follow:

- **Minimal model, maximal methods.** The model stays trivial (LV/RM) so that any rich behavior is
  attributable to the *methods*, and method-correctness can be checked against the analytic solution.
- **Characterization is the product.** The measurement layer — emergence detection, regime
  classification, a *morphospace* of composition → phenotype — is the open frontier and the aim.

## What works today

A working substrate, in `src/`:

- **Worlds as ACSets** — `schema.jl` (`TileWorld`), `world_gen.jl` (`grid_world`).
- **An ontology of interaction *shapes*** — `ontology.jl` (`birth_t`, `pred_t`, `death_t`, `crowd_t`,
  `move_t`); concrete processes are *typed into* these shapes.
- **A process registry + local-model assembly** — `subsystems.jl` (`assemble_local`); a subset of
  processes = a subsystem run in isolation, by config not code branch.
- **Ontology-agnostic composition** — `composition.jl` (`geography`, `stratify` via `typed_product`).
- **Name-based simulation** — `sim.jl` (`simulate`, `role_total`, …); rates keyed by process, state
  by role, never by position.

Validated against closed-form **ground truth**:

| model | result |
|---|---|
| Lotka–Volterra | neutral predator–prey cycle (the "tracer") |
| grass + prey | *is* LV one trophic level down (identical numbers) |
| tri-trophic (exponential grass) | predator collapse — the fragility |
| **Rosenzweig–MacArthur** (grass carrying capacity) | coexistence rescued; equilibria match analytics **to the digit** |

![Spatial Lotka–Volterra: oscillations and phase portrait](scripts/lv_minimal.png)

## Quickstart

From this directory:

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia --project=. scripts/run_mvp.jl    # spatial LV  -> scripts/lv_minimal.png
julia --project=. scripts/run_grass.jl  # grass ladder -> scripts/grass.png
julia --project=. scripts/run_rm.jl     # Rosenzweig–MacArthur K-sweep -> scripts/rm_sweep.png
```

Interactive use is recommended (`julia --project=.`, then `include("scripts/run_rm.jl")`) — see
the REPL walkthrough discussion in the design notes.

## Repository layout

```
src/        the substrate (schema, ontology, subsystems, composition, sim)
scripts/    runnable experiments (+ generated result plots)
docs/       design, theory, and research notes
```

## Documentation

- [`docs/simulation_laboratory_design_v2.md`](docs/simulation_laboratory_design_v2.md) — current
  architecture & strategy (v1 kept as the baseline it reworks).
- [`docs/roadmap.md`](docs/roadmap.md) — the ordered build plan with per-phase validation gates.
- [`docs/compositionality.md`](docs/compositionality.md) — why category theory: structure composes,
  behavior emerges.
- [`docs/dynamics_field_guide.md`](docs/dynamics_field_guide.md) — recurring dynamical models, their
  signatures, and how to recognize them.
- [`docs/references.md`](docs/references.md) — applied category theory, categorical systems,
  ecology, and ALife literature.
- [`docs/journal.md`](docs/journal.md) — the running engineering log.
- [`docs/handoff_decapodes_windows.md`](docs/handoff_decapodes_windows.md) — the field-path resume
  context (incl. a Windows `TetGen_jll` blocker; field path runs on Linux/WSL2).

## Roadmap (brief)

1. **Grass as a Decapodes field** coupled to the Petri populations (field↔population mass coupling).
2. **Characterization spine** — a "looks-right" DSL, refinement checks, the first morphospace slice.
3. **A single `Para(Optic)` agent** acting on the world.
4. *(deferred)* individual-based / graph-rewriting dynamics; a unified double-categorical frame.

Known blocker: the field path depends on `Decapodes`/`CombinatorialSpaces`, whose `TetGen_jll`
dependency fails to load on Windows (mingw pseudo-relocation `SIGABRT`, on both Julia 1.10 and 1.11).
It resolves cleanly alongside the population stack and is expected to work on Linux/WSL2 — details and
a ready-to-file upstream bug report are in the handoff doc.

---

*Built with [Catlab](https://github.com/AlgebraicJulia/Catlab.jl),
[AlgebraicPetri](https://github.com/AlgebraicJulia/AlgebraicPetri.jl), and
[DifferentialEquations.jl](https://github.com/SciML/DifferentialEquations.jl).*
