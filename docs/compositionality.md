# Why Category Theory: Compositionality and Emergence

The conceptual spine of the project, in one place. Pairs with `dynamics_field_guide.md` (the
behaviors) and `references.md` (the literature). The short version: **the rule composes; the
behavior emerges** — and category theory is what makes the first half rigorous so we can study the
second half honestly.

## The bet

The project is: take **primitive open systems** with known dynamics, **compose** them along the
spatial graph, and study the **new systems** that result — including behaviors no part had on its
own. Category theory is not decoration here; it is precisely the mathematics of *composition*, and
it is what keeps the composition correct and legible at scale.

## Two layers: structure (syntax) and behavior (semantics)

The crucial distinction, and the thing easy to blur:

### Structure composes functorially — predictable

- The wiring patterns (undirected wiring diagrams, the world graph) form an **operad**.
- Assigning a concrete system to each box and the composite to each wiring is an **algebra over
  that operad**. In our code, `oapply` and `typed_product` *are* that algebra map — they are
  **functors**: structure-preserving and lawful.
- Consequence: the composite net `z` is a **colimit / pullback** — *completely determined* by the
  parts and the wiring. There is nothing surprising about the *structure* of `z`. This is the
  rigor that lets us assemble thousand-transition nets without losing track of what is wired to
  what (the named `(role, tile)` / `(process, location)` provenance).

The open Petri nets we compose are **structured cospans** (a net with two boundary "feet"); their
category and its composition are worked out in the literature (see `references.md`).

### Behavior is where emergence lives — not predictable

There is a real, useful theorem here (Baez–Pollard): the map from an open reaction network to its
**rate equation (vector field)** is a **functor**. The vector field of the composite genuinely is
glued from the parts' vector fields. So the *local rule* is compositional — another reason the
approach is sound and scales.

But the **qualitative long-run behavior** — attractors, limit cycles, bifurcations, extinction,
spatial patterns — is **not** a simple function of the parts' behaviors. You cannot read
"the composite has a stable limit cycle" off "x oscillates" and "y decays." The map from composed
structure to *qualitative behavior* is the one that fails to preserve the compositional structure,
and that failure **is** the emergence.

So:

> **The rule composes functorially. The behavior does not. Category theory makes the first layer
> rigorous precisely so we can isolate and study the second.**

## Generative effects (the precise term)

"Generative effect" has a technical home (Fong & Spivak, *Seven Sketches*, ch. 1): it is when a
**functor fails to preserve joins/colimits** — `F(a ∨ b) ≠ F(a) ∨ F(b)`. The canonical example is
graph connectivity: join two systems and a connecting path can appear that neither had; the
connected-components functor doesn't preserve the join. The whole has a property the parts lack,
formalized exactly as *a map failing to commute with composition*.

Our emergence is the same shape of phenomenon: the assignment of *qualitative behavior* to a
composed system does not commute with composition. The functorial semantics we *do* have (the
vector field; the steady-state "black-boxing" relation) capture the **rule** and the
**input/output relation** — but not the full phenomenology of trajectories (multistability,
onset of oscillation, transients, patterning). That residue is the generative part.

## Why this matters for how we work

- **Rigor where it's possible, experiment where it's necessary.** CT gives a correct, scalable way
  to assemble the *rule*. The *lab* (harness, characterization, the LV "tracer") exists because the
  behavior of the assembled rule is genuinely emergent and must be *observed*. If behavior were
  naively compositional, there'd be no need for a lab at all.
- **Emergence becomes legible.** Because the structure is composed by a known functor, we always
  know exactly what was wired together. So when a surprising behavior appears, it is attributable
  to the *composition*, not to a bookkeeping slip. Categorical discipline is what makes a generative
  effect a *finding* rather than a *bug*.
- **Composites are first-class.** `z` is itself an open system, available to compose again. Systems
  compose into systems, indefinitely (the operadic / monoidal closure). "New systems" is literal.

## The core loop

```
  primitive systems  ──compose (functorial: oapply / typed_product)──▶  composite system
        ▲                                                                      │
        │                                                                 run + observe
        └──────── characterize the emergent regime (name it via the field guide) ◀──┘
```

Primitives with known dynamics → functorial composition (the CT engine) → emergent behavior →
characterize/name it → decide what to compose next. The category theory is the composition engine
that stays correct at scale; the lab is the observatory for the part that isn't predictable.

## A concrete instance we've already seen

Composing **grass + prey** (a known Lotka–Volterra system) with a **predator** (textbook) produced
**predator collapse** — a behavior not derivable from "LV" plus "a consumer." The net composed
cleanly and predictably (we built it; the counts were exact); the *behavior* surprised us. That is
the generative effect in miniature, and the reason rung 3 had to be *run*, not calculated.

See `references.md` for the papers and books behind every claim above.
