# Execution Roadmap

The actionable plan, aligned to `simulation_laboratory_design_v2.md` (strategy) and the two
near-term decisions taken in conversation. v2 says *what kind of project this is*; this says *what
we build, in what order, and how we know each step worked.*

---

## Summary

The project's purpose is to **push the categorical-systems / AlgebraicJulia frontier** —
contributing to *implementation of theory that currently exists mostly on paper* — using a
deliberately minimal **Lotka–Volterra / Rosenzweig–MacArthur** model as a **known-ground-truth
testbed**. Over-engineering the *methods* is intentional; the *model* stays trivial so that any
rich behavior is attributable to the methods and method-correctness can be checked against the
analytic LV/RM solution.

We have a working first-generation substrate (typed-Petri `typed_product` stratification) that
already reproduces LV, the grass ladder, and Rosenzweig–MacArthur — with the RM equilibria matching
closed-form to the digit (our arc-level correctness check). The next moves, in order:

1. **Grass as a Decapodes field** coupled to the Petri populations — the first (and hardest)
   field↔population *mass* coupling, drop moisture for now.
2. **A single `Para(Optic)` agent** acting on that world, rest of the populations unchanged.
3. Later, the deep frontier: all-agents / individual-based + structural (graph-rewriting) dynamics.

Throughout, **characterization is the research contribution** (v2 §6): the measurement instrument
starts as a ground-truth validator and grows into a *morphospace of emergence*.

---

## Where we are now (done)

**Substrate (working, precompiles):**
- World as an ACSet — `schema.jl` (`TileWorld`), `world_gen.jl` (`grid_world`).
- Process vocabulary — `ontology.jl`: `ONTOLOGY` with shapes `birth_t, pred_t, death_t, crowd_t`
  (the first new shape, `2→1`), `move_t`; `MOVE_TYPE`; `interaction_types()`.
- Process registry + local-model assembly — `subsystems.jl`: `Process`, `PROCESSES`,
  bundles (`LV_PROCESSES`, `GRASS_PREY`, `ECOSYSTEM`, `ECOSYSTEM_RM`), `assemble_local`.
- Composition — `composition.jl`: **ontology-agnostic** `geography`, `stratify` (`typed_product`).
- Simulation + introspection — `sim.jl`: `simulate`, `role_total`, `roles`, `process_keys`
  (rates keyed by process, state by role — name-based, never positional).
- Isolation = config switch: any subset of processes = a runnable subsystem.

**Models validated (against ground truth):**
- LV (the tracer); grass+prey = LV one trophic level down (identical numbers);
  tri-trophic `ECOSYSTEM` → predator collapse (the fragility); **RM** (`ECOSYSTEM_RM`) → predator
  rescued, equilibria match closed-form (`P*=m_q/b`, `G*=K/3`, `Q*≈G*−5`). Scripts: `run_mvp.jl`,
  `run_grass.jl`, `run_rm.jl`.

**Docs:** v1, v2, `compositionality.md`, `dynamics_field_guide.md`, `references.md`, `journal.md`.

**Known debt:** `viz.jl` is still positional/stale (exported with a warning); no formal
characterization layer yet (validation has been ad-hoc against closed forms).

---

## Operating principles (the discipline that makes over-engineering rigorous)

1. **Minimal model, maximal methods.** LV/RM is the fixed control. Complexity goes into the
   substrate, not the model.
2. **Over-engineer *well*.** Build ahead-of-implementation as real, reusable, ideally-upstreamable
   pieces — engage AlgebraicJulia/Topos. A throwaway hack that "approximates the theory" doesn't
   count as implementing it.
3. **Ground-truth + refinement is the correctness oracle.** Every method-experiment must (a)
   reproduce the analytic LV/RM result in its degenerate/uniform limit, and (b) survive a
   refinement check (grid, dt, system size, seed) before any "emergent" effect counts as real.
4. **Characterization is the product** (v2). The measurement layer is first-class, versioned, and
   grows into the research contribution.
5. **Adopt the frontier substrate when an experiment uses it** — liberally, since methods are the
   point — but instantiate concrete pieces (Decapodes, `Para(Optic)`), and treat **DCST as the
   organizing *vocabulary*** that the pieces realize, not a direct implementation target.
6. **Track predictions.** Especially v2's same-substrate-agents thesis and the field↔population
   composition claim. Log outcomes either way.

---

## The plan, in order

Each phase: **goal · what to build · the implementation gap (the contribution) · validation gate.**

### Phase 1 — Grass as a Decapodes field (first field↔population coupling)

- **Goal.** Promote grass from a Petri species to a continuous DEC field on the tile mesh, coupled
  to the Petri prey/predator populations by grazing — testing the *mass* exchange across the
  field/population boundary (the strong version of v2 §3's central claim).
- **Step 0 — dimensional reconciliation (on paper, first).** Promoting grass from a Petri
  amount-per-tile to a DEC density (0-form) changes its units; `r`, `K`, and the grazing rate must
  be re-dimensioned across the boundary. The "uniform reproduces RM" oracle will fail *spuriously*
  on a normalization mismatch long before any real coupling bug — so reconcile units up front, or
  you'll debug correct coupling logic.
- **Step 1 — pre-oracle ladder (validate the field machinery in isolation, before any coupling).**
  Each step has a closed-form check, so a failure is attributable to the DEC operator/BCs, not the
  coupling:
  - **(a) Constant field is stationary.** `g ≡ K` must be an *exact* fixed point (`∇²const = 0`,
    logistic zero at `K`). Drift ⇒ boundary conditions are leaking mass — **no-flux/Neumann BCs are
    load-bearing** for the whole uniform-RM oracle; test them explicitly.
  - **(b) Field-only logistic, no diffusion** → every vertex reaches `K`.
  - **(c) Field-only logistic + diffusion** → traveling front from a step IC at the **Fisher–KPP
    speed `c = 2√(rD)`**, converging to that value under mesh refinement. *This is the field-side
    analytic oracle — as rigorous as `P* = m_q/b` is for the populations.*
- **Step 2 — couple grazing (only after (a)–(c) pass).** Hand-coupled RHS first: one `ODEProblem`
  over `[grass field DOFs ; population DOFs]`; grass field gets a prey-dependent sink, prey ODE a
  grass-dependent source. **The working hand-coupled model is the deliverable.**
- **Step 3 — attempt a categorical expression of the coupling.** Time-boxed (see success criterion).
- **Gap / contribution.** There is (almost certainly) no turnkey "compose a Decapodes field with an
  AlgebraicPetri net." A clean, reusable composition of the two is the contribution (candidate
  upstream PR / worked example).
- **Validation gates.**
  - *Field machinery:* ladder (a)–(c); KPP front speed converges to `2√(rD)` under refinement.
  - *Coupling, degenerate limit:* uniform field + uniform populations reproduces RM equilibria.
  - *Mass-conjugacy invariant (the decisive test):* what leaves the field by grazing must reappear
    in the population, up to a stated efficiency `ε`:
    `d/dt ⟨grass⟩|_grazing = −(1/ε)·d/dt(prey)|_growth`. (For our stoichiometry `grass+prey→2prey`,
    `ε = 1`.) Use the *DEC-integrated* mass `⟨g,1⟩` (mass matrix), not a naive vertex sum. If the
    field loses mass that doesn't reappear in the populations, the coupling is wrong even when it
    "looks right" — this is what distinguishes a real mass coupling from a plausible fake.
  - *Refinement:* any spatial effect survives grid/dt/seed refinement (so the refinement-check
    harness is a **P1 prerequisite**, built minimally here — see Phase 2).
- **Pattern expectation (corrected).** Grass-as-a-*single*-field gives **Fisher–KPP fronts and
  saturation — NOT Turing/Klausmeier patterns.** Single-species reaction–diffusion does not
  spontaneously pattern; that needs ≥2 differentially-diffusing components (grass-field + a
  diffusing consumer, or a second field). So spatial *patterning* is a property of the **coupled**
  system, validated later against a dispersion relation derived for *our* kinetics — not assumed
  from Klausmeier's (water-advection) model. P1-grass-alone: expect fronts, not stripes.
- **Scoping honesty.** Grass is now mobile (field Laplacian), where the Petri grass was immobile.
  So only the **uniform regime** is back-comparable to prior RM results; any spatial behavior is a
  *genuinely new model*, not a refinement of the old one.
- **Success criterion (pre-commit).** The working hand-coupled model is **itself the success**,
  independent of whether the clean categorical composition materializes. The DEC↔Petri boundary may
  be exactly a site where two composition disciplines don't compose cleanly — a
  generative-effect-like obstruction. If so, *"we couldn't make it a clean functor, and here's
  precisely why"* is a reportable finding, not a failure. Time-box Step 3; ship Step 2 regardless.

### Phase 2 — Characterization spine (elevate the measurement instrument)

- **Goal.** Turn the ad-hoc ground-truth checks into the first-class, versioned characterization
  layer v2 calls the product.
- **Build.**
  - A small **"looks-right" DSL**: statistical assertions on aggregates + qualitative/topological
    assertions on regimes (fixed point vs. limit cycle vs. extinction vs. pattern).
  - The **refinement-check** harness (grid/dt/size/seed) as a reusable gate. *Built minimally in
    Phase 1 (it's a P1 prerequisite — you can't validate P1's spatial half without it); generalized
    and made reusable here.*
  - **Observable-as-artifact**: the macro-observable is explicit, swappable, versioned (generative
    effects are relative to the chosen observable).
  - The first **morphospace slice**: we already have one axis (the RM `K`-sweep = damping-strength
    vs `K`); formalize "composition/parameter → qualitative regime" as a structured lookup.
- **Gap / contribution.** This is the field's under-built side — the empirical functor
  *composition-structure → emergent phenotype*. Phenomenology, not prediction.
- **Validation gate.** The DSL must correctly classify the regimes we already understand (LV neutral
  cycle, RM stable focus, predator-collapse) before we trust it on novel ones.
- *(Phases 1 and 2 overlap: the Phase-1 oracle is the seed of the Phase-2 DSL.)*

### Phase 3 — A single `Para(Optic)` agent in the world

- **Goal.** Add one agent (a forager) as a purely additive, isolatable subsystem; rest of the
  populations unchanged. Establish the agent↔world composition pattern.
- **Build.**
  - Forward pass = policy(observation of local grass/prey); **Poly** interface for
    state-dependent action sets; backward pass = a real selection principle. **Lean RL-as-optic
    first** ("value iteration is optic composition" gives the template; active inference needs the
    agent to maintain a generative model — heavier). The contribution is the *bridge*, which is
    **objective-agnostic** — swap RL ↔ active inference later without touching it. Don't let the
    objective choice block the bridge.
  - **Hybrid execution**: agent acts at discrete decision epochs, world flows (ODE/PDE) between
    them via DiffEq callbacks.
  - Learning needs **episodes** → the agent loop reuses the Phase-2 harness.
- **Gap / contribution.** No turnkey "`Para(Optic)` agent driving a `DifferentialEquations` world."
  The discrete-decision/continuous-flow bridge is the contribution. **Tests v2 §5** (same-substrate
  agents) — log whether the agent really is "the same kind of arrow" as `lv_local`.
- **Validation gate.** World *without* the agent still matches ground truth (isolation); the agent
  measurably improves its objective over episodes.

### Phase 4 — The deep frontier (after more concept time)

- All populations → agents = the jump from **density modeling to individual-based modeling** (not
  just "add backward passes"): AlgebraicJulia **graph-rewriting ABM**, birth/death, open-endedness
  (structure promoted from authored to emergent). Mediator subsystems for O(1) agent wiring.
- **DCST** attempted as the organizing frame once fields + populations + agents must compose as one
  system. Story-sift = characterization over structural-event logs.
- Explicitly deferred — the user is sitting with these concepts; scope when ready.

---

## Order at a glance

```
[done] substrate + LV + grass ladder + RM (ground-truth validated)
  1. grass → Decapodes field, coupled to Petri populations   (field↔population mass coupling)
  2. characterization spine                                   (looks-right DSL, refinement, morphospace)
  3. single Para(Optic) agent on the world                   (agent↔dynamics bridge)
  4. all-agents / individual-based + graph rewriting + DCST   (deferred frontier)
```

Phases 1–2 interleave (the refinement-check harness is built *in* P1 as a prerequisite, then
generalized in P2); 3 builds on both; 4 needs more concept time.

---

## Decisions still pending (to sit with)

- **Agent objective & backward pass:** forage/harvest vs. movement; RL-as-optic vs. active
  inference. (Determines Phase 3's shape.)
- **When prey/predator also become fields** (full reaction–diffusion) vs. stay Petri/agents.
- **DCST framing depth** — how hard to push the unified double-categorical composition vs. let it
  stay vocabulary.
- **Mediator design** for the multi-agent step (Phase 4).

---

## Validation gates, collected

The non-negotiable oracle, per phase:
- **P1:** field ladder (a) const stationary / (b) →K / (c) KPP front `2√(rD)`; uniform coupling
  reproduces RM equilibria; **mass-conjugacy invariant** holds (field loss = population gain, ÷ε);
  any spatial effect survives refinement. *(Dimensional reconciliation done first; refinement
  harness built here.)*
- **P2:** DSL classifies known regimes (LV cycle, RM focus, collapse) correctly.
- **P3:** agent-free world matches ground truth; agent improves its objective.
- **P4:** individual-based limit recovers the density model at scale; structural events are typed
  (correct-by-construction), not imperative glue.

*Living document — revise as phases complete and predictions resolve; keep `journal.md` as the
running log of what actually happened.*
