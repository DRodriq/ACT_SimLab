# Further Reading & References

Sources behind the architecture (`compositionality.md`), the substrate, and the dynamics catalog
(`dynamics_field_guide.md`). Grouped by theme. Citations are best-effort from memory — **verify
identifiers (arXiv numbers, years, venues) before relying on them**; titles/authors are the
reliable handles for searching.

---

## Applied category theory & compositionality

- **Fong & Spivak, *Seven Sketches in Compositionality: An Invitation to Applied Category
  Theory*** (2018, arXiv:1803.05316; book ed. Cambridge UP, 2019). Ch. 1–2 cover **generative
  effects**, Galois connections, and orders/colimits. The accessible entry point.
- **Brendan Fong, *The Algebra of Open and Interconnected Systems*** (DPhil thesis, Oxford, 2016).
  Decorated cospans; the formal home of generative effects in open systems.
- **Lawvere, *Functorial Semantics of Algebraic Theories*** (PhD thesis, Columbia, 1963). The
  origin of "syntax is a category, semantics is a functor" — the idea under the whole structure/
  behavior split.
- **Spivak, *The Operad of Wiring Diagrams*** (2013, arXiv:1305.0297). Wiring diagrams as an
  operad; systems-in-boxes as an algebra over it.

## Categorical systems: open nets, reaction networks, dynamical systems

- **Baez & Pollard, *A Compositional Framework for Reaction Networks*** (Rev. Math. Phys., 2017;
  arXiv:1704.02051). The key result for us: the open-reaction-network → rate-equation (vector
  field) assignment is **functorial**. "The rule composes."
- **Baez, Fong & Pollard, *A Compositional Framework for Markov Processes*** (J. Math. Phys., 2016;
  arXiv:1508.06448). Black-boxing as a functor (steady-state input/output semantics).
- **Baez & Master, *Open Petri Nets*** (Math. Struct. Comp. Sci., 2020; arXiv:1808.05415). The
  categorical foundation for the open Petri nets we compose.
- **Baez & Courser, *Structured Cospans*** (Theory Appl. Categ., 2020; arXiv:1911.04630). The
  general machinery behind open systems with boundaries (the "feet").
- **Vagner, Spivak & Lerman, *Algebras of Open Dynamical Systems on the Operad of Wiring
  Diagrams*** (Theory Appl. Categ., 2015; arXiv:1408.1598). Composing arbitrary dynamical systems
  (not just mass-action) on wiring diagrams — the basis of AlgebraicDynamics.

## The AlgebraicJulia stack (the tools we're using)

- **Patterson, Lynch & Fairbanks, *Categorical Data Structures for Technical Computing*** (
  Compositionality, 2022; arXiv:2106.04703). ACSets and Catlab — the data structures our worlds
  and Petri nets are built from.
- **Libkind, Baas, Halter, Patterson & Fairbanks, *An Algebraic Framework for Structured Epidemic
  Modelling*** (Phil. Trans. R. Soc. A, 2022; arXiv:2203.16345). Typed Petri nets, `oapply_typed`,
  and **stratification via `typed_product`** — the exact substrate our composition uses.
- **Software:** Catlab.jl, AlgebraicPetri.jl, AlgebraicDynamics.jl (AlgebraicJulia org). Catalyst.jl
  and DifferentialEquations.jl (SciML) for flexible rate laws and integration.
  - Rackauckas & Nie, *DifferentialEquations.jl* (J. Open Res. Softw., 2017).
  - Loman et al., *Catalyst: Fast and flexible modeling of reaction networks* (PLoS Comput. Biol.,
    2023) — arbitrary/Hill rate laws if mass-action becomes limiting.

## Population & community ecology

- **Lotka, *Elements of Physical Biology*** (1925); **Volterra** (1926). The predator–prey model.
- **Verhulst** (1838). The logistic equation.
- **Rosenzweig & MacArthur, *Graphical Representation and Stability Conditions of Predator–Prey
  Interactions*** (Am. Nat., 1963). Logistic prey + saturating predation — the realistic model.
- **Rosenzweig, *Paradox of Enrichment*** (Science, 1971). Enrichment destabilizes — the Hopf
  bifurcation to limit cycles.
- **Gause, *The Struggle for Existence*** (1934). Competitive exclusion principle.
- **Tilman, *Resource Competition and Community Structure*** (1982). R* theory — who wins on which
  resource; mechanism behind biome zonation.

## Functional responses & resource limitation

- **Holling, *The Components of Predation...*** (Can. Entomol., 1959). Type I/II/III responses.
- **Monod, *The Growth of Bacterial Cultures*** (Annu. Rev. Microbiol., 1949). Saturating
  resource-limited growth (= Michaelis–Menten = Holling II).
- **Michaelis & Menten** (1913). Enzyme-kinetics origin of the saturation form.
- **von Liebig** (1840s). Law of the minimum — growth set by the scarcest resource.
- **Beddington (1975); DeAngelis et al. (1975).** Predator-interference / ratio-dependent
  responses (when Type II isn't enough).

## Spatial dynamics & pattern formation

- **Turing, *The Chemical Basis of Morphogenesis*** (Phil. Trans. R. Soc. B, 1952). Diffusion-
  driven instability → spontaneous patterns.
- **Klausmeier, *Regular and Irregular Patterns in Semiarid Vegetation*** (Science, 1999). Banded
  vegetation from reaction–diffusion — directly relevant to emergent grass/biome patterning.

## Soil & ecosystem biogeochemistry

- **Parton et al.** (1987). CENTURY soil organic-matter model (multi-pool, first-order, climate-
  modulated).
- **Coleman & Jenkinson** (1996). RothC soil carbon model.
- **Liski et al.** (2005). Yasso soil carbon model.

## Dynamical systems / general (for reading the "signatures")

- **Strogatz, *Nonlinear Dynamics and Chaos*** (1994/2015). Fixed points, stability, Hopf
  bifurcations, limit cycles — the vocabulary for the field-guide signatures.
- **Murray, *Mathematical Biology* I & II** (3rd ed., 2002/2003). Comprehensive reference for
  population, reaction–diffusion, and pattern-formation models.

## Categorical cybernetics, agents, lenses & games

The frontier for "agents that perceive and act on the world, compositionally" — the natural home
for adding agents to the ecology substrate (see `compositionality.md`, the agent-composition
question).

- **Ghani, Hedges, Winschel & Zahn, *Compositional Game Theory*** (LICS 2018; arXiv:1603.04641).
  Open games — compositional agents-with-strategies built from lenses.
- **Riley, *Categories of Optics*** (2018; arXiv:1809.00738). Lenses/optics as composable
  bidirectional `(get, put)` processes — "perceive state, act back on it."
- **Capucci, Gavranović, Hedges & Rischel, *Towards Foundations of Categorical Cybernetics*** (
  ACT 2021; arXiv:2105.06332). The `Para(Optic)` construction unifying games, learners, agents.
- **Fong, Spivak & Tuyéras, *Backprop as Functor*** (LICS 2019; arXiv:1711.10455). Learning as
  compositional — the gradient-descent agent as a functor.
- **Spivak & Niu, *Polynomial Functors: A Mathematical Theory of Interaction*** (book, 2021).
  `Poly` — open *interactive* dynamical systems with mode-dependent interfaces (agents choosing
  actions). Basis of the interactive side of AlgebraicDynamics.
- **Myers, *Categorical Systems Theory*** (book draft, ongoing). Double-categorical framework
  unifying open dynamical systems and their composition.
- **Smithe, *Mathematical Foundations for a Compositional Account of the Bayesian Brain*** (DPhil
  thesis, 2023). Categorical active inference — agents with internal models perceiving and acting.

## Compositional modeling — precedents in other fields

Where "compose primitives into systems" is already mature (and, in spots, structure *does* predict
behavior).

- **Feinberg, *Foundations of Chemical Reaction Network Theory*** (Springer, 2019); deficiency-zero
  theorem (Feinberg 1972; Horn & Jackson 1972). The precedent that qualitative behavior can be
  read off network *structure* — directly relevant to the "is the emergence gap fundamental?"
  thread.
- **Paynter, bond graphs** (1961); **Modelica** (acausal, port-based component modeling); Cellier,
  *Continuous System Modeling* (1991). Compositional modeling as the dominant *engineering*
  paradigm.
- **Danos & Laneve, *Formal Molecular Biology*** (2004, Kappa); **Faeder, Blinov & Hlavacek,
  BioNetGen** (2009). Rule-based / compositional systems biology.

## Artificial life, artificial societies & emergence

The lineage this project's "Holy Grail" sits in — emergence from simple rules, mostly *without* a
tractable compositional substrate underneath (the gap we're aiming at).

- **Anderson, *More is Different*** (Science, 1972). The canonical statement of emergence.
- **Epstein & Axtell, *Growing Artificial Societies: Social Science from the Bottom Up*** (1996).
  Sugarscape — the founding artificial-society model (terrain + agents + rules).
- **Reynolds, *Flocks, Herds, and Schools*** (SIGGRAPH 1987). Boids — emergence from local rules.
- **Ray, *An Approach to the Synthesis of Life*** (1991, Tierra); **Adami & Ofria, Avida**.
  Digital evolution / open-ended evolution.
- **Chan, *Lenia: Biology of Artificial Life*** (2019; arXiv:1812.05433); Flow-Lenia. Continuous
  cellular automata with lifelike emergent structures.
- **Gardner / Conway, Game of Life** (Scientific American, 1970). The emergence touchstone.
- **Dittrich, Ziegler & Banzhaf, *Artificial Chemistries — A Review*** (Artificial Life, 2001).

## Communities, venues & on-ramps

Where this work lives and how to engage it (the practical path to collaborators / grad school).

- **Topos Institute** (Berkeley) — applied CT research hub; seminars, open community. (Spivak,
  Patterson, et al.)
- **AlgebraicJulia** — the Catlab/AlgebraicPetri/AlgebraicDynamics ecosystem (Fairbanks @ U.
  Florida, Patterson). Active **Zulip** chat; open to contributors.
- **Cybernetics Institute / categorical cybernetics** (Hedges, Strathclyde) — open games, lenses,
  the agent frontier.
- **Applied Category Theory (ACT)** conference and the **Adjoint School** (annual mentored
  research program — a concrete on-ramp for prospective grad students).
- **ALIFE** — International Conference on Artificial Life (the ALife/emergence community).

---

*Add references here as new dynamics or methods enter the lab; keep the entry next to the model it
justifies in `dynamics_field_guide.md` where possible.*
