module Ontology

using AlgebraicPetri

export ONTOLOGY, MOVE_TYPE, interaction_types

# The movement / spatial-coupling transition type. Everything else is a "local" interaction.
const MOVE_TYPE = :move_t

# The process vocabulary (the "type system"). One species TYPE (:Pop); one transition type per
# process *shape*. Concrete processes (prey_birth, grass_growth, ...) are typed into these
# shapes, and many distinct processes may share a shape. This grows as new dynamics are added
# and is versioned on its own axis, in parallel with the world schema. See docs/journal.md.
const ONTOLOGY = LabelledPetriNet(
    [:Pop],
    :birth_t => (:Pop => (:Pop, :Pop)),          # 1 -> 2
    :pred_t  => ((:Pop, :Pop) => (:Pop, :Pop)),  # 2 -> 2
    :death_t => (:Pop => ()),                     # 1 -> 0
    :crowd_t => ((:Pop, :Pop) => :Pop),           # 2 -> 1  (self-limitation / carrying capacity)
    MOVE_TYPE => (:Pop => :Pop),                  # 1 -> 1  (movement between patches)
)

# All transition types that represent LOCAL interactions (everything but movement). The
# geography factor carries reflexives of these so that ANY local model can stratify onto it
# without the geography needing to know which processes are present.
interaction_types() =
    [tname(ONTOLOGY, t) for t in 1:nt(ONTOLOGY) if tname(ONTOLOGY, t) != MOVE_TYPE]

end # module Ontology
