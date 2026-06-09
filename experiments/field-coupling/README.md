# Field Coupling (Decapodes engine)

**Status:** migrated — **separate engine** (DEC fields), not a harness `Scenario`. Paths co-located;
re-verify before trusting.
**Question:** Does a continuous (Decapodes/DEC) grass field couple to populations with mass
conservation, and reproduce the Fisher–KPP front?

## Scenario / steps
The DEC field path (not the K-currency harness). Three steps:
- `field_kpp.jl` — 1-D Fisher–KPP front (front speed → `2√(rD)`).
- `field_couple.jl` — field ↔ population mass coupling (mass-conjugacy gate, drift 0).
- `field_spatial.jl` — 1-D traveling grazing wave.

## Run
`julia --project=. experiments/field-coupling/field_kpp.jl` (etc.) → `outputs/`.

## Result
Validated against closed form: KPP front speed (with the Bramson log correction), **mass-conjugacy
drift 0**, uniform→equilibrium rel.err 0. See `docs/journal.md`.

## Notes
This is the **field engine** (Decapodes/CombinatorialSpaces), distinct from the population harness —
kept for the validated field results. One of the project's *two engines*.
