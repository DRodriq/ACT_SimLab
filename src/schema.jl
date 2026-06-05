#= The schema for our world tiles
# @present declares a catergory-theorectic schema
# Ob (objects) are types of things - Tile, Edge
# The morphisms are typed relationships (src, tgt)
# AttrType plus Attr let us attach data to objects
# @acset_type turns this schema into a julia type that can be instatiated
=#

module Schema

using Catlab
using Catlab.CategoricalAlgebra

export SchTileWorld, TileWorld

@present SchTileWorld(FreeSchema) begin
    Tile::Ob
    Edge::Ob
    src::Hom(Edge, Tile)
    tgt::Hom(Edge, Tile)

    Real::AttrType
    x::Attr(Tile, Real)
    y::Attr(Tile, Real)
end

@acset_type TileWorld(SchTileWorld, index=[:src, :tgt]){Float64}

end