# IGP Phase Diagram

**Status:** validated
**Question:** How does the intraguild-predation outcome (fox wins / wolf wins / coexist) depend on
fox competitiveness (sheep→fox attack rate) and productivity (grass carrying capacity)?

## Scenario

A one-currency (biomass) **intraguild-predation module** on the harness:
`grass → sheep → {fox, wolf}`, plus `fox → wolf`. So the wolf is the **IG-predator** (eats both sheep
and fox), the fox the **IG-prey** (eats sheep, eaten by wolf), and sheep the **shared resource**.
Built with `SimLab`'s `Scenario`/`Pool`/`Feed`. Two swept axes via `sweep2`: the `sheep→fox` rate
(fox competitiveness) × grass `crowd` (lower → higher carrying capacity → more productive).

## Run

```
julia --project=. experiments/igp-phase-diagram/run.jl     → outputs/phase_diagram.png
```

**Gate:** every run conserves biomass (`@assert all(c.conserved for c in M)`).

## Result

The textbook **Holt–Polis** structure, emergent from the substrate (299 runs, all conserved):

- a **role-reversal boundary** — wolf wins at low fox competitiveness, fox wins at high;
- **productivity dependence** — the boundary *tilts*: higher productivity favors the **IG-predator**
  (wolf), the central Holt–Polis prediction;
- a **coexistence knife-edge** — three-way coexistence appears only in a thin band on the boundary.

![IGP phase diagram](outputs/phase_diagram.png)

## Notes

Produced entirely by the harness pipeline `Scenario → sweep2 → classify → figure` — the first real
characterization artifact. Migrated from the old `scripts/regime_map.jl`. Background:
[`docs/community_modules.md`](../../docs/community_modules.md) (the IGP module) and
[`docs/journal.md`](../../docs/journal.md) (2026-06-08).
