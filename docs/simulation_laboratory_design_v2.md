# Simulation Laboratory: System Design (v2)

A compositional simulation laboratory in the AlgebraicJulia ecosystem, starting from spatial
Lotka–Volterra and scaling toward a Dwarf-Fortress-class open-world generator. This is v2: a
re-foundation of `simulation_laboratory_design.md` (v1) in light of a June 2026 frontier scan and
the design analysis that accompanied it. v1 is kept intact so its predictions can be checked
against reality; this document records what changed and why.

---

## 0. What this v2 loads from

This rework is synthesized from three bodies of material. Naming them up front so the provenance of
each decision is traceable.

**A. The existing SimLab corpus (carried forward).**
- `simulation_laboratory_design.md` (v1) — the architecture this document reworks.
- `compositionality.md` — the substrate argument and the agent-composition question.
- `dynamics_field_guide.md` — the catalog of dynamical "signatures" the lab is meant to produce.
- `references.md` — already-strong coverage of the foundations *and the right frontier lanes*
  (categorical cybernetics, Poly, Myers' CST, open games, ALife, plus the emergence-gap question
  via Feinberg's deficiency-zero theorem and Turing/Klausmeier patterning). Most of v2's "frontier"
  is the *latest instances within lanes references.md already tracks*, not a new direction.
- `journal.md` — the working log.

**B. The 2024–2026 frontier layer (new; not yet in references.md).** Identifiers verified in the
June 2026 scan. These are the current instances of the lanes you were already tracking:
- **Myers & Libkind, *Towards a Double Operadic Theory of Systems*** (arXiv:2505.18329, 2025) —
  the consolidation of Myers' CST into a single unified composition substrate (a symmetric monoidal
  loose right module over a double category). The successor to the "book draft, ongoing" you cite.
- **Myers, *Nondeterministic Behaviours in Double Categorical Systems Theory*** (arXiv:2502.02517,
  2025) — the behaviour side for stochastic systems.
- **Smithe, *Structured Active Inference*** (arXiv:2406.07577, 2024) — agents built *on* categorical
  systems theory; agents as controllers dual to their generative models; mode-dependent interfaces;
  agents-managing-agents; self-restructuring meta-agents. The successor to Smithe's 2023 thesis you
  cite, and the single most important paper for our agent layer.
- **Hedges & Rodríguez Sakamoto, *Reinforcement Learning in Categorical Cybernetics*** (
  arXiv:2404.02688, 2024), with the companion result **"Value Iteration is Optic Composition"** —
  RL agents as `Para(Optic)` morphisms; Bellman backup = precomposition with an optic.
- **"Agent Policies from Higher-Order Causal Functions"** (arXiv:2512.10937, Feb 2026) — frontier;
  reward-seeking agents via higher-order causal functions (authorship to confirm).
- **Spivak & Niu, *Polynomial Functors*** — now **formally published, Cambridge UP, Sept 2025**
  (the 2021 draft you cite is the same work; cite the book as canonical).
- **Morris, Baas, Arias, Gatlin, Patterson & Fairbanks, *Decapodes*** (J. Computational Science 81,
  2024; arXiv:2401.17432) — spatialized PDEs via discrete exterior calculus in AlgebraicJulia, plus
  the AlgebraicJulia **agent-based-modeling-via-graph-rewriting** capability.
- Sociological signal: **"Double Categorical Systems Theory for Safeguarded AI"** (funded project) —
  the categorical-systems community is being funded to do AI-in-the-loop-over-categorical-systems,
  i.e. our Milestone 5, as frontier research.

**C. Analytical conclusions from the design conversation (the reasoning behind the rework).**
- *The compositionality–emergence tension.* Compositional methods work by making the whole a
  functor of the parts; strong emergence is precisely the failure of that. Emergence always lives in
  the **gap between two functors** — one preserving composition (assembly), one not (the property
  you care about). Generative effects names that gap. Corollary: **the categorical machinery
  assembles; it does not predict or characterize.** (Confirmed by the Turing/RG acid test: the
  framework hands you the operator and goes silent at the eigenvalue.)
- *Build-and-observe is the right epistemics.* We renounce a-priori prediction (weak emergence,
  Bedau; ALife's "synthesis not analysis", Langton). Reproducible ≠ real: discretization/chaos
  artifacts must be discriminated by refinement, not trusted.
- *Agents are not a separate kind of thing.* An agent is a subsystem (lens / `Para(Optic)`) with a
  non-trivial **backward pass** carrying a selection/optimization/inference principle. World and
  agent are the same kind of arrow. The agent/world boundary is a chosen factorization (Markov
  blanket), not an ontological seam.
- *Creation is fine; do it as typed rewriting.* Dynamic coupling and birth of new subsystems are
  fully expressible. Done as **typed graph rewriting** they stay correct-by-construction; done as
  imperative glue they silently lose that guarantee. Open-endedness (unbounded growth, novel types)
  is the genuine frontier — it promotes *structure* from authored to emergent.
- *Characterization is the open frontier and your wedge.* The compositional-modeling field has the
  assembly side solved and the observation/"looks right"/emergence-detection side wide open. v1
  already identified this ("harness is the product", "characterization is the final boss"). v2
  promotes it from a harness sub-component to **the laboratory's research contribution.**

---

## 1. The strategic thesis (new in v2)

> **You are one generation behind on the substrate and ahead of the field on the characterization
> problem. So invert the effort: adopt the frontier substrate wholesale, and spend your own
> research energy on the layer the field has under-built.**

Concretely:
- **Stop hand-rolling the composition substrate.** v1 hand-builds `oapply`-to-ODE over
  AlgebraicPetri + structured cospans (the 2019–22 generation). Adopt Double Categorical Systems
  Theory (Myers–Libkind 2025) + AlgebraicDynamics + Decapodes + Poly + graph rewriting as the
  foundation. Let the published substrate carry the weight v1 was carrying by hand.
- **Re-found agents as same-substrate now**, not as a Milestone-6 rewrite. Smithe's Structured
  Active Inference puts agents on the *same* categorical-systems-theory substrate as the world.
- **Own characterization.** The novel contribution is an **empirical functor: composition-structure
  → emergent phenotype**, discovered by simulation and organized by the categorical structure — a
  *morphospace* of emergence. This is what "harness is the product" becomes when taken seriously as
  research rather than engineering.

The bet of v1 was that the categorical discipline would let the architecture reach the open-world
frontier "without rewrites." v2's refinement: that bet is *won at the substrate layer by adopting
the frontier*, and the real open problem — the one worth your years — is characterization, which no
amount of better composition solves.

---

## 2. Guiding principles (carried from v1, with one promotion)

Unchanged and validated:
- **Composition over enumeration.** (And note: this beats the Wolfram enumeration trap — your
  composition axis is *meaningful*, where rule-enumeration is not.)
- **Properties not types.** Biomes/regimes/kinds are emergent clusters in state-space, identified
  post-hoc. (This is weak emergence, operationalized correctly.)
- **Schema as a tunable, versioned artifact**; migrations as explicit functors (Catlab schema
  migration).
- **Subsystem isolation before composition**; isolation is a *config change, not a code branch* —
  the load-bearing payoff of categorical structure.

**Promoted to first principle in v2:**
- **The harness is the product, and characterization is the research.** v1 had this as a layer and a
  watch-point. v2 makes it the organizing purpose. The simulation engine is plumbing; the
  characterization/emergence-detection layer is the contribution. Design everything else to feed it.

---

## 3. The substrate, updated

| Concern | v1 (first-gen) | v2 (frontier substrate) |
|---|---|---|
| Composition theory | hand-rolled `oapply` over structured cospans | **Double Categorical Systems Theory** (Myers–Libkind 2025) as the organizing frame; `AlgebraicDynamics` for the dynamics |
| Continuous fields (moisture, temp, hydrology, weather) | diffusion as Petri transitions across edges | **Decapodes** (DEC-based spatial PDEs) natively |
| Populations & discrete events | AlgebraicPetri | keep AlgebraicPetri / typed Petri (`typed_product` stratification, per your epidemic-modeling reference) |
| Interfaces | fixed boundary places | **Poly** for *mode/state-dependent* interfaces (required once actions depend on state) |
| Structural change / creation | "discrete event injection" (vague) | **typed graph rewriting** (DPO on ACSets); AlgebraicJulia ABM-via-rewriting |
| Agents | Milestone-6 rewrite replacing species | **same substrate + backward pass** (`Para(Optic)` / Structured Active Inference) |

The division of labor is the key design decision: **Decapodes for fields, Petri/ABM for
populations and discrete events, Poly/Para(Optic) for agents, graph rewriting for structural
dynamics, DCST as the frame that lets them compose as one system.** They are all open systems; DCST
is the vocabulary in which "all the same kind of arrow" is literally true.

---

## 4. The pipeline (reworked)

```
┌──────────────────────────────────────────────────────────────────────────┐
│  SCHEMA LAYER (Catlab / ACSets)                                          │
│    @present SchWorld — tiles, edges, property attributes. Versioned.     │
│    Migrations between versions are explicit functors.                    │
└──────────────────────────────────────────────────────────────────────────┘
                                    ▼
┌──────────────────────────────────────────────────────────────────────────┐
│  WORLD GENERATION LAYER                                                  │
│    ACSet instance: tiles, edges, properties. Generators as before.      │
└──────────────────────────────────────────────────────────────────────────┘
                                    ▼
┌──────────────────────────────────────────────────────────────────────────┐
│  SUBSYSTEM LAYER  (three kinds, one composition discipline)             │
│    • Fields      → Decapodes (DEC PDEs): moisture, temp, hydrology       │
│    • Populations → AlgebraicPetri (typed): flora, fauna, trophic levels  │
│    • Agents      → Para(Optic) / active-inference: forward = act,        │
│                    backward = select/optimize/infer                      │
└──────────────────────────────────────────────────────────────────────────┘
                                    ▼
┌──────────────────────────────────────────────────────────────────────────┐
│  COMPOSITION LAYER  (DCST frame; oapply / AlgebraicDynamics)            │
│    World ACSet → diagram of open systems → composed total system        │
│    Agents wired in through MEDIATOR subsystems (market, network) so      │
│    interfaces stay O(1), not O(N).                                       │
└──────────────────────────────────────────────────────────────────────────┘
                                    ▼
┌──────────────────────────────────────────────────────────────────────────┐
│  DYNAMICS LAYER  (AlgebraicDynamics + DifferentialEquations.jl)         │
│    ODE / SDE / Gillespie / hybrid. Callbacks emit state to the harness.  │
└──────────────────────────────────────────────────────────────────────────┘
                                    ▼  (discrete structural events)
┌──────────────────────────────────────────────────────────────────────────┐
│  STRUCTURAL-DYNAMICS LAYER  (new) — typed graph rewriting               │
│    Birth/death of subsystems, rewiring, settlement formation as TYPED    │
│    DPO rewrites on the world ACSet. Correct-by-construction structure    │
│    change. The mechanism behind open-endedness.                         │
└──────────────────────────────────────────────────────────────────────────┘
                                    ▼
┌──────────────────────────────────────────────────────────────────────────┐
│  CHARACTERIZATION + HARNESS LAYER  (the product)                        │
│    ParameterStore | TimeSeriesCapture | ScenarioRunner | SweepRunner     │
│    CHARACTERIZATION (elevated): emergence detection, phenotype clustering │
│    Diagnostic | Visualization | AI-assist (itself a Para(Optic) agent)   │
└──────────────────────────────────────────────────────────────────────────┘
```

Two structural additions over v1: an explicit **structural-dynamics layer** (graph rewriting) for
creation/open-endedness, and the **characterization layer promoted** to co-headline with the
harness.

---

## 5. Agents as same-substrate (the re-founded seam)

v1: agents are "trait-based creatures replacing typed species," a Milestone-6+ rewrite, with the
categorical discipline as the *bet* that no rewrite will be needed. v2 collapses the seam now.

- An agent **is** an open system — the same kind of object as `lv_local` — with a **backward pass**
  carrying a selection principle. Forward = perceive/act; backward = best-response (games) /
  gradient (learning) / Bayesian inversion (active inference). `Para(Optic)` is the construction;
  Smithe's Structured Active Inference is the agent-native instance, built on the same CST substrate
  as the world.
- **No "replace species" step.** A trophic species is a subsystem with a trivial backward pass; an
  agent is the same subsystem with a non-trivial one. Specialization = parameters (`Para`);
  learning/adaptation = a backward optic on those parameters.
- **Wire agents through mediators.** Don't give each agent N−1 ports. Reify connectivity
  (market, social network, matching) as its *own* subsystem holding the adjacency as state; each
  agent gets one O(1) port to it. This keeps interfaces small and localizes dynamic/endogenous
  wiring into one legible, handoff-able subsystem. Markets, fields, shared resources all use this
  pattern.
- **State-dependent action sets** (an agent's available moves depend on its state) are exactly what
  **Poly** interfaces express — the reason Poly (not fixed boundary places) is the agent interface.

Design consequence: the Milestone-1 prey and the Milestone-6 agent should be *the same type of
arrow* in the codebase. If they aren't, the substrate is wrong.

---

## 6. Characterization as the research contribution (elevated)

This is where v2 asks you to spend your originality, because it's the open frontier.

- **The empirical functor.** Treat the lab as discovering a map *composition-structure → emergent
  phenotype* by simulation, organized by the categorical structure of the compositions. This is a
  *morphospace of emergence*: which compositions yield which qualitative regimes. It is
  phenomenology (a structured lookup table), not prediction — and that's the honest, defensible
  framing.
- **Which properties are compositional vs. not.** A real, refereeable research output is the
  *classification*: which emergent properties are preserved under composition (some conserved
  quantities, certain monotone/stability properties — cf. Feinberg deficiency-zero, which you
  already flagged) and which are generative effects (not preserved). Mapping that boundary is the
  rigorous skeleton under the morphospace.
- **The observable problem is first-class.** Composition does not tell you *what to measure*, and
  the choice of observable determines whether you see emergence at all (generative effects are
  relative to the chosen functor). So the characterization layer must treat "choice of macro-
  observable" as an explicit, swappable, versioned artifact — like the schema.
- **Reproducible ≠ real.** Every detected "emergent" effect must pass a refinement check (grid, dt,
  system size, seed) before it counts. Turing-type patterns are discretization-sensitive; build
  artifact-discrimination into characterization, not as an afterthought.
- **The "looks right" DSL** (v1's idea) is the operational core: statistical assertions on
  aggregates + topological/qualitative assertions on regimes. v2's addition: these assertions *are*
  the emergence-detectors, and the corpus of them is the lab's accumulating scientific instrument.

---

## 7. AI-assist as categorical cybernetics (reworked Milestone 5)

v1 treats AI-assist as a late bolt-on (propose params → human approves → closed-loop search). v2:
the AI-assist loop **is itself an agent in the same substrate** — a `Para(Optic)` morphism whose
forward pass reads characterizations and whose backward pass proposes parameter/structure changes
over the ParameterStore. "Value iteration is optic composition" (Hedges 2024) is the template; the
funded "DCST for Safeguarded AI" project is the frontier doing exactly this. Framing the tuner as a
same-substrate agent means the lab and its optimizer compose by the identical discipline — and the
"describe what you want, the system iterates toward it" goal becomes a backward-pass design problem,
not a separate engineering effort.

This also connects to your own `model-discovery` thread (NN-driven model discovery near the edge of
chaos): the discovery loop and the tuning loop are the same `Para(Optic)` shape.

---

## 8. Build-out roadmap (reworked; milestones preserved, tooling updated)

Milestones 0–2 are essentially unchanged from v1 — get the pipeline running, spatial LV with
property-dependent rates, then the characterization/diagnostic loop. The reworks land from M3 on.

- **M0 — pipeline skeleton (days).** Two tiles, LV each, diffusion between. Every layer talks.
  *(unchanged)*
- **M1 — spatial LV, property-dependent rates (weeks).** 50×50 grid, Perlin properties, sweep over
  predation × diffusion. *(unchanged, but: prototype `diffusion` via Decapodes alongside the Petri
  version and compare — this decides the fields-vs-Petri division early.)*
- **M2 — characterization + diagnostic loop (weeks).** *(unchanged in scope; elevated in priority —
  this is now the core, not a supporting layer. Start the "looks right" DSL and the refinement-check
  discipline here.)*
- **M3 — subsystem expansion (weeks–months).** Flora/herbivore/carnivore as separate subsystems;
  **weather and hydrology as Decapodes fields, not Petri edges.** Verify isolation/pairwise/composed.
- **M4 — stochasticity & disturbance (months).** Gillespie/hybrid; disturbance via the
  **structural-dynamics (graph-rewriting) layer**, not ad-hoc event injection.
- **M5 — AI-assisted tuning (months).** Build it as a `Para(Optic)` agent over the ParameterStore
  (see §7), not a bolt-on.
- **M6+ — the open-world frontier.** Agents are **not** a rewrite here — they are the same-substrate
  arrows established from M1 (see §5), now given non-trivial backward passes and structural
  (rewriting) dynamics. Settlements/economy = agents + mediator subsystems + rewriting. Story-sift =
  characterization over structural-event logs.

**Prediction-tracking (per v1's closing discipline):** the v1 claim most worth checking is "the
categorical discipline lets us reach the open world without rewrites." v2's refinement is testable:
*if agents end up needing a substrate different from the world subsystems, the same-substrate thesis
(§5) failed.* Log it either way.

---

## 9. Frontier dependencies & anti-reinvention (new)

Before building any substrate component, check whether it already exists. The recurring failure mode
is rebuilding 2021 by hand. Known existing pieces:
- Composition of open dynamical systems → `AlgebraicDynamics.jl` (don't re-derive oapply-to-ODE).
- Typed Petri stratification → `oapply_typed` / `typed_product` (your epidemic-modeling reference).
- Spatial PDEs → `Decapodes.jl` (don't approximate diffusion with Petri edges if a field is meant).
- ABM with structural change → AlgebraicJulia graph-rewriting ABM (don't hand-roll birth/death).
- Unified composition frame → DCST (Myers–Libkind) — adopt the vocabulary even where you can't yet
  adopt an implementation.
- Agent constructions → `Para(Optic)`, open games, Structured Active Inference — don't invent an
  agent abstraction; instantiate one of these.

When something genuinely doesn't exist, that absence is a contribution worth naming (likely in the
characterization layer).

---

## 10. Key risks & watch-points (updated from v1)

Carried from v1 (still true): AlgebraicJulia maturity / version churn; composition performance
(cache by world+config hash); the temptation to over-engineer the substrate before any dynamics run
(Milestone 0 in *days*); characterization is the hard problem; schema growth multiplies the tuning
surface; visualization debt.

New in v2:
- **Substrate breadth risk.** v2 depends on *more* frontier libraries (Decapodes, rewriting, Poly
  tooling), several research-grade. Mitigate by adopting them *incrementally* and keeping the v1
  Petri path as a working fallback per subsystem until the frontier path is proven.
- **The reinvention reflex.** §9 exists because the strongest pull is to rebuild what the frontier
  already ships. Default to adopting; justify any hand-roll.
- **Characterization scope creep.** Promoting characterization to "the research" risks it
  swallowing the project. Keep it grounded in the "looks right" DSL and concrete morphospace
  questions; don't try to formalize emergence in general.

---

## What this document is not

Still not a specification — a working hypothesis about the right architecture, revised against the
2026 frontier. v1 remains the baseline; this is the bet that the substrate question is answered by
*adopting* the frontier and the originality belongs in characterization. The same honesty clause
applies: commit it, edit it as you learn, and track which predictions held — especially the
same-substrate-agents thesis (§5) and the substrate-adoption bet (§1).
