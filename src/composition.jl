module Composition

using AlgebraicPetri, AlgebraicPetri.TypedPetri
using Catlab, Catlab.Programs, Catlab.WiringDiagrams, Catlab.CategoricalAlgebra
using ..Ontology

export geography, stratify

"""
    geography(world)

Build the spatial factor from a `TileWorld`: one `:Pop` junction per tile, one `:move_t`
transition per directed edge (src → tgt). Every tile also carries reflexives of *all* local
interaction types, so the geography is agnostic to which local model gets stratified onto it —
the same geography composes with flora-only, prey-only, or the full system unchanged.
"""
function geography(world)
    ntile = nparts(world, :Tile)
    uwd = RelationDiagram(repeat([:Pop], ntile))
    js  = Int[]
    for i in 1:ntile
        j = add_junction!(uwd, :Pop, variable = Symbol("t$i"))
        set_junction!(uwd, ports(uwd, outer = true)[i], j, outer = true)
        push!(js, j)
    end
    tnames = Symbol[]
    for e in 1:nparts(world, :Edge)
        box = add_box!(uwd, [:Pop, :Pop], name = MOVE_TYPE)
        set_junction!(uwd, ports(uwd, box)[1], js[world[e, :src]])
        set_junction!(uwd, ports(uwd, box)[2], js[world[e, :tgt]])
        push!(tnames, Symbol("mv$e"))
    end
    geo = oapply_typed(ONTOLOGY, uwd, tnames)
    gm  = dom(geo)
    add_reflexives(geo, [interaction_types() for _ in 1:ns(gm)], ONTOLOGY)
end

"""
    stratify(local_model, world)

Glue a local (single-patch) typed model over the world's geography and return the composed
Petri net (`dom` of the typed product). Species are `(role, tile)` and transitions are
`(process, location)`.
"""
stratify(local_model, world) = dom(typed_product(local_model, geography(world)))

end # module Composition
