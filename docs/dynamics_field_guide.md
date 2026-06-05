# Dynamics Field Guide

A fast-identification layer for the recurring growth/interaction dynamics this lab produces.
*Not* a textbook — just the models that keep reappearing, how they map onto our substrate, how to
recognize them by their behavioral **signature**, and when to keep them in mind while designing
the low-level ontologies/processes. Pair with `journal.md` (what we've actually built) and the
system design doc (the architecture).

Two ideas to hold throughout:

- **Topology vs. functional response are separate layers.** The Petri *shape* (stoichiometry —
  who consumes whom, in what ratio) is one choice; the *rate law* (how the rate depends on
  densities) is another. The same shape can carry a Type I, Type II, or saturating response.
  Shape lives in the ontology; rate law lives in the parameter/harness layer.
- **Stocks vs. forcings.** Stocks are the ODE variables (Petri species); forcings (temperature,
  season) live *inside the rate coefficients*. See journal / design doc.

---

## 1. Mass-action decoder (shape → ODE term)

Under mass-action, a transition's rate = `coefficient × ∏(inputs)`, and it adds/removes
stoichiometric amounts. So each ontology shape contributes a known term:

| shape | reaction | ODE contribution | classic term |
|---|---|---|---|
| `birth_t` | `X → 2X` | `+rX` | exponential growth |
| `death_t` | `X → ∅` | `−mX` | linear decay / mortality |
| `pred_t` | `X+Y → 2Y` | `−aXY` (X), `+aXY` (Y) | bilinear interaction (Holling I) |
| `crowd_t`* | `X+X → X` | `−cX²` | logistic self-limitation |
| `move_t` | `X@i → X@j` | `±d·X` between patches | linear diffusion (graph Laplacian) |

\* not yet in the ontology — the first `2→1` shape, added when carrying capacity is needed.

To get a **saturating** (non-mass-action) rate, two routes: (a) make the coefficient a function of
state via `valueat(f,u,t)` — e.g. coefficient `a/(1+ah·X)` turns `pred_t` into Holling II; or
(b) add a mechanistic substate (handling/searching) and let saturation emerge from pure
mass-action (à la Michaelis–Menten from `E+S⇌ES→E+P`).

---

## 2. The recurring models

Each entry: **form** · *substrate mapping* · **signature** (how to recognize it) · *reach for it
when* · lit.

### Exponential (Malthusian)
`dN/dt = rN` (r>0 growth, r<0 decay). · `birth_t` or `death_t` alone. · **Signature:** straight
line on a log plot; unbounded growth or decay to zero; no equilibrium except 0. · *The null model;
also a red flag — any stock with only `birth_t` will blow up.* · Malthus 1798.

### Logistic
`dN/dt = rN(1 − N/K)`. · `birth_t` + `crowd_t` (`r` and `c=r/K`). · **Signature:** S-curve
(sigmoid) rising to a plateau `K`; monotone, no overshoot; self-stabilizing. · *Any self-limited
stock: grass on finite soil, a population at carrying capacity.* · Verhulst 1838.

### Lotka–Volterra (predator–prey)
`dx/dt = rx − axy`, `dy/dt = axy − my`. · `birth_t`(x) + `pred_t` + `death_t`(y). · **Signature:**
**neutral closed orbits** — sustained oscillations whose amplitude is set by initial conditions,
predator peak lags prey by ~¼ period. Structurally *unstable*: a conserved quantity, knife-edge.
· *The familiar tracer. If you see perfect neutral cycles, you have NO density dependence anywhere
— usually a sign something stabilizing is missing.* · Lotka 1925, Volterra 1926.

### Rosenzweig–MacArthur (the realistic predator–prey)
Logistic prey + **Holling II** predation: `dx/dt = rx(1−x/K) − a x y/(1+ahx)`,
`dy/dt = e a x y/(1+ahx) − my`. · `birth_t`+`crowd_t` on prey, `pred_t` with a *saturating* rate,
`death_t` on predator. · **Signature:** below a threshold → **damped spiral** to a stable
coexistence point (stable focus); enrich (raise `K`) past a **Hopf bifurcation** → a **stable
limit cycle** of *fixed* amplitude (independent of initial conditions, unlike LV); enrich further →
large cycles that graze zero and risk extinction (**paradox of enrichment**). · *The default
"grown-up" predator–prey model; reach for it the moment plain LV is too fragile (our rung-3
collapse).* · Rosenzweig & MacArthur 1963; Rosenzweig 1971 (enrichment).

### Holling functional responses
Per-capita consumption vs prey density. **Type I:** linear `aX` (mass-action default).
**Type II:** saturating `aX/(1+ahX)` (handling time) — *same form as Monod/Michaelis–Menten*.
**Type III:** sigmoidal (refuge/learning), stabilizing at low density. · *Choose the response when
defining a consumer process; Type II is the common realistic default.* · Holling 1959.

### Monod / chemostat (resource-limited growth)
`μ = μ_max · S/(K_s + S)` — growth saturating in substrate `S`. Mathematically identical to
Holling II / Michaelis–Menten. · A `birth_t` whose coefficient is a Monod function of a resource
stock. · **Signature:** growth rate flat-then-saturating as resource rises; in a chemostat, washout
below a critical dilution, steady state above. · *Microbial/plant growth limited by one nutrient or
water.* · Monod 1949; Michaelis–Menten 1913.

### Liebig's law of the minimum (multi-resource)
`growth = μ_max · min(f(water), g(N), h(light), …)` — set by the *scarcest* resource. · A `birth_t`
whose coefficient is a `min` over several resource stocks/forcings. · **Signature:** growth tracks
one limiting factor at a time; switching limiter produces kinks/regime changes across space. ·
*Grass growth once it depends on >1 soil resource — likely needed for forest/grassland zonation.* ·
von Liebig 1840s.

### Lotka–Volterra competition
`dN_i/dt = r_i N_i (1 − (N_i + Σ α_ij N_j)/K_i)`. · Two+ logistic species sharing a resource (or
explicit `crowd_t`/cross terms). · **Signature:** **competitive exclusion** (one →0, Gause) when
interspecific competition dominates; **stable coexistence** when each limits itself more than its
rival; outcome can depend on initial conditions (priority effects / alternative stable states). ·
*The mechanism behind "forest vs grassland" emerging — two flora types on shared soil/water.* ·
Gause 1934; MacArthur consumer–resource theory.

### Soil organic-matter pool models (CENTURY / RothC / Yasso)
Multiple carbon **pools** (litter → fast → slow → passive) with **first-order** transfer and loss,
rates modulated by temperature & moisture. · Pools = species; transfers = `death_t`/`move_t`-shaped
(mostly *linear*); temp/moisture = **forcings** on the coefficients. · **Signature:** multi-
exponential relaxation; very slow (years–decades) pools → **stiff** dynamics next to fast biota. ·
*The template for the soil layer; mostly a linear Petri net + forcing-modulated rates — the easy
case.* · Parton 1987 (CENTURY); Jenkinson & Coleman (RothC); Liski 2005 (Yasso).

### Linear reservoir (bucket hydrology)
`dV/dt = inflow − kV` (outflow ∝ storage). · A water stock with a first-order `death_t`-shaped
outflow + a source (rain) + `move_t` flow along edges (optionally gravity/elevation-weighted). ·
**Signature:** exponential recession after rain; storage tracks a smoothed inflow. · *The minimal
hydrology stock; texture/permeability are forcings on `k`.* · standard hydrology.

### Reaction–diffusion patterning (Turing / Klausmeier)
Local reaction + diffusion can make a *uniform* state spontaneously form spatial patterns
(spots/stripes/labyrinths) when an activator diffuses slower than an inhibitor/resource. ·
Our `move_t` coupling + local nonlinear reactions on the tile graph. · **Signature:** structure
(patches, bands) emerging from homogeneous initial conditions *without* an imposed gradient; on
slopes, banded vegetation. · *Keep in mind once water + grass diffuse at different rates — biome
patterning may be emergent, not just terrain-driven.* · Turing 1952; Klausmeier 1999 (vegetation
bands).

---

## 3. Reverse lookup — signature → suspect

What you see in a run → what to suspect (the fast-ID layer):

| Observed behavior | Likely model / cause | Note |
|---|---|---|
| Unbounded growth | exponential; missing density dependence | add `crowd_t` / a limiter |
| S-curve to a plateau | logistic / resource saturation | healthy self-limitation |
| Neutral closed orbits (amplitude = f(init)) | pure LV | structurally unstable; something stabilizing is missing |
| Damped oscillation → fixed point | stable focus (e.g. RM below Hopf) | coexistence, self-limited |
| Fixed-amplitude limit cycle (init-independent) | RM past Hopf / paradox of enrichment | check if enrichment is driving it |
| Boom then crash to ~0 of the top level | consumer can't establish; over-enrichment | our rung-3 collapse |
| One competitor → 0 | competitive exclusion | interspecific > intraspecific competition |
| Two stable outcomes from different inits | alternative stable states / priority effects | bistability |
| Kinks / regime switches across space | Liebig min, limiter switching | multi-resource |
| Multi-exponential slow relaxation | pool model (soil C) | stiffness risk |
| Patterns from uniform start | Turing / reaction–diffusion instability | emergent, not terrain-driven |

---

## 4. Notes for the ontology / subsystem-design level

When adding a process or species, keep these in mind *before* composing:

- **Pick topology and functional response separately.** First the shape (stoichiometry), then the
  rate law. Don't bake a constant rate in if the real process saturates.
- **Mass-action default is Type I.** That's fine for a first pass and for genuinely linear
  processes (decay, diffusion, soil transfer). Flag explicitly when a process needs Type II/Monod
  (consumer feeding, nutrient uptake) or `min` (multi-resource growth).
- **Every stock needs a brake.** A species with only `birth_t` blows up. Make sure something —
  predation, crowding, washout — closes the loop, or expect exponential blow-up.
- **Forcings modulate coefficients; stocks are variables.** If a quantity has no feedback into it,
  it's a forcing in a rate function, not a species.
- **Mind timescales.** Soil/hydrology (years–days) vs biota (seasons) → stiff systems; a stiff
  solver (not `Tsit5`) will be needed once they share one net.
- **Two ways to implement saturation** (state-dependent rate vs mechanistic substate) — choose per
  primitive; the mechanistic route keeps pure mass-action at the cost of extra states.
- **Annotate each `Process`** with the named model + functional-response it represents, so the
  registry doubles as a grounded primitive library.

---

*Scope note: this guide is deliberately partial — the models above are the ones expected to recur
in an ecology/terrain simulation. Add an entry when a new dynamic earns its place by actually
showing up.*
