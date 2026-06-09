# Two-Currency Web — PLANNED

**Status:** planned (rebuild on the harness; needs graded carcass/SOM pool features in the engine)
**Question:** On the full green+brown web (stoichiometric feeding, carcass cast-off, scavenging,
decomposition), does scavenging break the IGP exclusion — and where is the balanced regime?

## Scenario (to build)
K=2 web: grass / sheep / fox / wolf + carcass + SOM + fungus + mineral. Predator-specific carcass
cast-off; general scavenging; Liebig assimilation. A `sweep2` regime map over the load-bearing knobs
(fungus turnover × SOM decay × fox utilization).

## Run
*(to be written — requires harness features: graded dead pools + aging)* → `outputs/`.

## Notes
Rebuild of `scripts/two_currency_web.jl`. The balanced-coexistence regime is a **narrow window**
between "fungus hoards everything" and "fungus dies and everything collapses" — a sweep target.
See `docs/journal.md` (2026-06-08, Stage 2).
