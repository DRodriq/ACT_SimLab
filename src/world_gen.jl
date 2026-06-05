#=
# World Generator
# Right now we are just instatiating a world as an nxn list of tiles
# where edges are connetions between tiles
#
=#

module WorldGen

using ..Schema
using Catlab.CategoricalAlgebra

export grid_world

function grid_world(n::Int)
    world = TileWorld()
    # add n*n tiles with positions
    for i in 1:n, j in 1:n
        add_part!(world, :Tile, x=Float64(i), y=Float64(j))
    end
    # Add edges: 4-connected adjacency, both directions
    tile_id(i, j) = (i-1)*n + j
    for i in 1:n, j in 1:n
        here = tile_id(i, j)
        for (di, dj) in [(1,0), (-1,0), (0,1), (0,-1)]
            ni, nj = i+di, j+dj
            if 1 <= ni <= n && 1 <= nj <= n
                add_part!(world, :Edge, src=here, tgt=tile_id(ni, nj))
            end
        end
    end
    world
end

end