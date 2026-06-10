# Status & Re-grounding

The **read-this-first** doc — what the project is, how we work, where we are. It supersedes the
"**X is the product**" framing (v1/v2/roadmap/README) and the "more than one engine" framing that the
realigned `engines.md` replaces.

## What this is

An **open-ended exploration — no product, no finish line.** A modeling laboratory whose real subject
is **category theory**: we use ecology / ABM-adjacent models *only* because their dynamics are known
and verifiable, so any difficulty is attributable to the **methods**. The aim is to tie categorical
concepts and tools into increasingly sophisticated **compositional** models (working toward
agent-based ones) and, in doing so, **work toward the edges of the theory and the available tools.**
The categorical work *is* the point; the sim is the testbed. Characterization (regime maps, the
composition→phenotype functor) is a **rich frontier we work at**, not a thing to finish — and neither
is the substrate.

## How we work (the method)

- **Categorical-first; one composition discipline.** Not "one engine that does everything easily" —
  *one categorical discipline* into which new subsystem **types** (populations, fields, currencies,
  agents) are added as categorical citizens. Functorial composition *is* the modularity we want.
- **Work *with* blockers, never around them.** When something doesn't fit, re-establish the *real*
  blocker and find the categorical path. A place where the tools run out **is the frontier we're here
  for** — extend the substrate or contribute upstream; never hand-roll *outside* the theory.
- **Minimal model, maximal methods.** LV/RM is the fixed control; complexity goes into the substrate.
- **Ground-truth + refinement is the oracle.** Every method-experiment reproduces the analytic result
  in its degenerate limit and survives a refinement check before any "emergent" effect counts.

## Where we are (2026-06-08)

**Working substrate (Catlab 0.17.5):**
- **Petri populations** — typed-Petri `typed_product` stratification (`src/{ontology,subsystems,
  composition,sim}.jl`). LV / grass-ladder / RM validated to closed form; spatial *via stratification*.
- **Decapode fields** — DEC reaction–diffusion (`field-*` experiments), validated (KPP front,
  mass-conjugacy).
- **A characterization tier** — `Scenario` (forcings), `sweep2`, `classify` → regime maps. *This half
  is good and stays.*

**The known drift, being realigned** (see `drift_diagnosis.md`). A hand-rolled, *non-categorical* ODE
currency engine grew inside the harness (`generate`, the parallel `Pool`/`Feed` vocabulary) and did
the flagship work. **Decision: one categorical engine.**
- **Spatial hand-roll (`run_spatial`, `spatial-foodweb`)** — *no real blocker* (Petri `typed_product`
  already stratifies). → revert to categorical stratification.
- **Conserved currencies** — *a real blocker* (mass-action Petri has no ledger; ε=1 is structural) and
  exactly the edge we want. → make currencies a **categorical subsystem type on Catlab 0.17** (a
  currency-bearing ACSet + a dynamics functor over AlgebraicPetri's composition machinery). Off-the-
  shelf `StockFlow` / `AlgebraicDynamics` are **version-blocked** (no Catlab 0.17 release) — so this is
  *frontier extension, not adoption*. That gap is the work.

## What we've learned (durable)

- The **representation ladder** (field ↔ discrete ↔ agent), scale-matched per quantity.
- **Conserved energy/matter** with an *emergent* `E/N` quality axis (carcass ↔ fertilizer) arising from
  differential outflows — no "aging" primitive needed.
- **Community modules** (food chain / apparent / exploitative competition / IGP) as composable building
  blocks; a real **Holt–Polis phase diagram** from a sweep.
- The **dynamics field guide** (signatures of recurring models).
- That **off-the-shelf categorical currency-dynamics is a genuine tool gap** on this stack — a place to
  contribute.

## Immediate next

Make currencies a **categorical subsystem type on Catlab 0.17** (the realignment) and revert the
spatial hand-roll to `typed_product` stratification. Then `Scenario` / `sweep2` / `classify` ride on
top unchanged, and there is **one categorical composition discipline**.
