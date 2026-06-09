# Grass–Prey–Predator (RM coexistence) — PLANNED

**Status:** planned (rebuild on the harness, K=1)
**Question:** Does the harness reproduce Rosenzweig–MacArthur coexistence — grass carrying capacity
rescuing the predator from the tri-trophic collapse?

## Scenario (to build)
One-currency biomass: **logistic grass → prey → predator**. Contrast exponential grass (predator
collapse) vs logistic grass (coexistence rescued). Optionally sweep carrying capacity into a
damping/regime map (the old `run_rm` K-sweep, as a `sweep2`).

## Run
*(to be written — copy `../_template/`)* → `outputs/`.

## Notes
Rebuild of the old `scripts/run_rm.jl` (RM K-sweep) as a harness `Scenario`. See `docs/journal.md`
(RM) and `docs/dynamics_field_guide.md` (Rosenzweig–MacArthur). *Note:* mass-action (Type I) RM is
globally stable — the sustained limit cycle needs a saturating Type II response (a future engine
primitive).
