# Discrete Grid (Petri stratification)

**Status:** migrated — Petri-stratification engine; output path co-located.
**Question:** What does the discrete tile-graph (stratified Petri) tri-trophic model look like
evolving in space, rendered honestly per-cell?

## Scenario
The stratified Petri model (`ECOSYSTEM_RM` over `grid_world(12)`) — prey/predator seeded centrally,
diffusing tile-to-tile via `move_t`; rendered as a per-cell `heatmap` (no interpolation, honest to
the discrete substrate).

## Run
`julia --project=. experiments/discrete-grid/run.jl` → `outputs/grid_anim.mp4`.

## Result
The discrete-representation counterpart of the field demo: prey graze and spread tile-to-tile, the
predator fills the wake.

## Notes
Uses the Petri stratification (`stratify`/`assemble_local`), not the currency harness. The
discrete-vs-continuum pairing — see `docs/journal.md` (2026-06-06).
