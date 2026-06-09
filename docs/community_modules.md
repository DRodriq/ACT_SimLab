# Community Modules — Composable Building Blocks

Ecology already decomposes complex systems into small, recurring **interaction modules**. This is a
ready-made library of *validated primitives* for a compositional lab: build a module, ground it in
known dynamics or data, then compose modules into a full web. Pairs with `compositionality.md` (the
category-theory spine — *why* composition + emergence), `dynamics_field_guide.md` (the behavioral
signatures), and `references.md` (literature).

> One sentence: **the module is the unit of reuse; the web is what you get when you compose modules
> along shared species.**

## 1. What a module is

A **community module** (Holt 1997, "Community modules") is a small subset of species (canonically
three) with a specific interaction topology — the smallest unit that already exhibits non-trivial
dynamics. Real food webs are statistically built from a handful of recurring modules; **motif
analysis** (Milo 2002; Stouffer & Bascompte 2010) characterizes whole webs by the frequency of
these 3-node subgraphs. So "modules → webs" is not our invention; it is how the field reads nature.

In our substrate a module is just a **sub-web**: a set of `Species` + `Feed` rows (the
`foodweb_*.jl` data), or equivalently a subset of typed processes (`assemble_local`). Nothing
special distinguishes a "module" from a "system" — *composites are first-class* (cf.
`compositionality.md`), which is exactly what lets a validated module be dropped into a larger web.

## 2. The four canonical 3-species modules

| module | topology | dynamical signature | lit |
|---|---|---|---|
| **Tri-trophic food chain** | `A→B→C` | trophic cascade (apex suppresses middle, releases base); biomass ≠ energy flow (residence time decouples them) | Hairston 1960; Oksanen 1981 |
| **Exploitative competition** | `R→C₁, R→C₂` | competitive exclusion (Gause) unless the consumers partition the resource / self-limit | Gause 1934; MacArthur |
| **Apparent competition** | `A→P, B→P` | two prey indirectly suppress each other *through* the shared predator; boosting one can extinguish the other | Holt 1977 |
| **Intraguild predation (IGP) / omnivory** | `R→C, R→P, C→P` | predator both eats and competes with the intermediate; three-way coexistence is a **narrow knife-edge** — generically one consumer is excluded | Polis & Holt 1989; Holt & Polis 1997 |

These compose: a 4-species web is two overlapping modules sharing species. `grass→sheep→wolf`
(chain) + a fox that eats sheep and is eaten by wolf = chain ∪ IGP, glued along `sheep` and `wolf`.

## 3. Mapping to the substrate

- **Module = sub-web (data).** A few `Species`/`Feed` rows, or a process subset. Adding a module to
  a web = adding its rows; the generator regenerates the dynamics unchanged (`foodweb_fox.jl` added
  IGP to the chain with *only data*).
- **Composition = gluing along shared species.** Categorically a pushout/colimit over the shared
  nodes — the same functorial composition `compositionality.md` describes (`oapply`/`typed_product`
  for the Petri side). The *structure* of the composite is determined; only the *behavior* is open.
- **Conserved currency keeps modules honest.** Each `Feed` is a biomass flow (ε in, 1−ε to
  detritus), so a module is energetically closed and composes without conservation leaks — verified
  to ~1e-12 even across an extinction (`foodweb_*.jl`). This is what lets modules be glued freely:
  the ledger is preserved under composition.
- **Validate-then-compose.** Because a module is small, it can be *calibrated to a studied system or
  dataset* (real LV cycles, a measured IGP system, a chemostat) and only then composed. The full
  web is then assembled from empirically-grounded parts — the inverse of fitting one giant model.

## 4. Why composing modules is interesting (the emergence payoff)

Per `compositionality.md`: structure composes functorially, **behavior does not**. Modules are where
this bites concretely and legibly. Composing the **IGP module** onto the chain produced behavior
*in none of the parts*:

- **Competitive role-reversal with a sharp threshold.** `foodweb_igp_flip.jl`: below `sheep→fox ≈
  0.65` the wolf excludes the fox (→ grass→sheep→wolf chain); above it the fox excludes the wolf (→
  grass→sheep→fox chain). Winner-take-all, discontinuous, with a *trophic-cascade difference* between
  the two regimes (fox-wins releases grass: 42 vs 25). None of "chain," "fox eats sheep," or "wolf
  eats fox" predicts which predator survives, or that the answer is bistable across a threshold.
- **Coexistence is the knife-edge, not the rule.** Three-way IGP coexistence didn't appear in the
  scan — matching Holt & Polis: it requires the IG-prey to be the superior resource competitor
  *within a productivity-dependent window*. That the module is *hard* to coexist is itself the
  finding, and it's emergent.

This is a generative effect in miniature, and the reason a module must be *run*, not read off its
topology. Categorical discipline makes the outcome *attributable to the composition* (we know
exactly what was glued), so a surprise is a finding, not a bug.

## 5. The building block, and the workflow

Modules join **fields** (DEC) and **agents** (Para/Optic) as a class of composable primitive — the
*population/interaction* building block, now energetically grounded by the conserved currency. The
working loop:

```
pick a module ─▶ calibrate to known dynamics/data ─▶ compose along shared species
      ▲                                                          │
      └────── characterize the emergent web regime (field guide) ◀┘
```

## 6. Open directions

- **Adaptive foraging / preference** — predator effort allocated to the more profitable prey
  (density- or energy-dependent attack rates). A richer module *primitive* (state-dependent flow);
  known to stabilize apparent competition and shift IGP outcomes. The bridge to the agent layer.
- **Module phase diagrams** — sweep a module's parameters and map the survival/coexistence regions
  (our own Holt–Polis diagram, a Gause exclusion boundary). The characterization spine applied to a
  module.
- **Spatial modules** — a module per tile + dispersal: local exclusion with regional coexistence
  (the competition–colonization tradeoff), source–sink rescue. Modules on the discrete grid.
- **Data-matched modules** — calibrate a module to a measured system, compose calibrated modules,
  ask whether the web's emergent behavior matches the real web's. The empirical version of the bet.
