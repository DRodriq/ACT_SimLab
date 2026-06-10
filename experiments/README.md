# Experiments

Each experiment = a **Scenario** (or, for the field/Petri engines, a configured model) + a procedure
+ **co-located outputs**. *A harness experiment directory ↔ a `Scenario` instance.* Run any with:

```
julia --project=. experiments/<id>/run.jl       # writes experiments/<id>/outputs/
```

## Harness experiments (the K-currency engine; each is a `Scenario`)

| id | question | status |
|---|---|---|
| [lv-two-species](lv-two-species/) | reproduce the LV neutral cycle? | validated |
| [trophic-chain](trophic-chain/) | standing biomass from a conserved chain — does it pyramid? | validated |
| [biomass-pyramid](biomass-pyramid/) | does conversion efficiency ε set the predator:prey ratio? | validated |
| [igp-phase-diagram](igp-phase-diagram/) | IGP outcome (fox/wolf/coexist) vs competitiveness × productivity | validated |
| [grass-prey-predator](grass-prey-predator/) | does a carrying capacity stabilize tri-trophic coexistence? (+ composition graph) | validated |
| [spatial-foodweb](spatial-foodweb/) | a Scenario distributed over a grid — spatial invasion wave, conserved | validated |
| [two-currency-engine](two-currency-engine/) | emergent E/N quality on the nutrient cycle | planned |
| [two-currency-web](two-currency-web/) | green+brown web — does scavenging break IGP exclusion? | planned |

## Other-engine experiments (kept; not `Scenario`s)

| id | engine | question | status |
|---|---|---|---|
| [discrete-grid](discrete-grid/) | Petri stratification | discrete tile-graph tri-trophic, rendered per-cell | migrated |
| [field-coupling](field-coupling/) | Decapodes (DEC) | grass field ↔ populations; KPP front; mass conservation | migrated |
| [field-tritrophic](field-tritrophic/) | Decapodes (DEC) | tri-trophic Decapode; 2-D spatial patterns | migrated |

*The lab runs on several **engines** — the K-currency population **harness** (now both well-mixed and
spatial via `run_spatial`), the **Petri stratification** (discrete-grid), and the **DEC field** engine;
`Para/Optic` agents are the planned next. Only harness experiments are `Scenario`s. See
[`../docs/engines.md`](../docs/engines.md).*

## Adding an experiment

Copy [`_template/`](_template/) → `<id>-<name>/`, fill its `README.md`, write `run.jl`: build a
`Scenario`, run/sweep, write `outputs/`, and **assert a gate** (conservation drift or a known result).

## Status legend

- **validated** — carries a gate (conservation, or matches a closed-form / known result).
- **planned** — README describes what to build; not yet implemented.
- **migrated** — code preserved from the old `scripts/`; may need a re-verify (especially the field engine).

## Conventions

- Outputs live in `<id>/outputs/` (1:1 with the experiment — no orphaned global figures).
- The README is the durable, agent-readable record; `docs/journal.md` is the chronological narrative.
- Prefer expressing config as a `Scenario` — one that *can't* be is a signal the engine is missing a primitive.
