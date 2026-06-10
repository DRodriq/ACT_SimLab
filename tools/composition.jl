# Composition-graph renderer — a reader of the harness. Draws a Scenario's structure: pools as nodes
# (laid out by trophic level), feeds as solid "eats" arrows (resource → consumer), and death/loss to
# the detritus sink as light dashed edges. Usage:
#     include(".../tools/composition.jl"); composition_graph(scn, "outputs/composition.png")

using CairoMakie

function composition_graph(scn, path; title="composition")
    feedmap = Dict{Symbol,Vector{Symbol}}()
    for f in scn.feeds; push!(get!(feedmap, f.consumer, Symbol[]), f.resource); end
    level = Dict{Symbol,Int}()
    function lvl(n, seen=Set{Symbol}())
        haskey(level,n) && return level[n]
        n in seen && return 0
        res = get(feedmap, n, Symbol[])
        l = isempty(res) ? 0 : 1 + maximum(lvl(r, push!(copy(seen),n)) for r in res)
        level[n] = l; l
    end
    living = [p for p in scn.pools if p.name != scn.detritus]
    for p in living; lvl(p.name); end
    maxl = isempty(level) ? 0 : maximum(values(level))

    bylevel = Dict{Int,Vector{Symbol}}()
    for p in living; push!(get!(bylevel, level[p.name], Symbol[]), p.name); end
    pos = Dict{Symbol,Point2f}()
    for (lev,ns) in bylevel, (i,n) in enumerate(ns)
        x = length(ns)==1 ? 0.0 : 2*((i-1)/(length(ns)-1)) - 1
        pos[n] = Point2f(x, Float64(lev))
    end
    pos[scn.detritus] = Point2f(1.35, -0.6)
    rolecol(p) = p.role==:producer ? :seagreen : p.role==:dead ? :gray60 : :indianred
    shrink(p0,p1,s) = (d=p1-p0; n=sqrt(d[1]^2+d[2]^2); n<1e-6 ? (p0,p1) : (p0+(d/n)*s, p1-(d/n)*s))

    fig = Figure(size=(440, 150+135*(maxl+2)))
    ax = Axis(fig[1,1], title=title); hidedecorations!(ax); hidespines!(ax)
    for p in living                                   # death/loss → detritus (dashed)
        a,b = shrink(pos[p.name], pos[scn.detritus], 0.30)
        lines!(ax, [a[1],b[1]], [a[2],b[2]]; color=(:gray,0.35), linestyle=:dash, linewidth=1)
    end
    for f in scn.feeds                                # feeds (solid arrow, resource → consumer)
        a,b = shrink(pos[f.resource], pos[f.consumer], 0.30)
        arrows!(ax, [a[1]], [a[2]], [b[1]-a[1]], [b[2]-a[2]]; color=:black, arrowsize=13, linewidth=2)
    end
    for p in scn.pools                                # nodes
        scatter!(ax, [pos[p.name]]; markersize=52, color=(rolecol(p),0.55), strokecolor=rolecol(p), strokewidth=2)
        text!(ax, pos[p.name]; text=string(p.name), align=(:center,:center), fontsize=11)
    end
    limits!(ax, -1.7, 1.9, -1.15, maxl+0.55)
    save(path, fig); path
end
