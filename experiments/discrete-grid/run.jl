# Discrete-grid animation: watch the stratified (Petri tile-graph) model evolve — one flat color
# PER CELL (Makie `heatmap` is cell-based: no interpolation), honest to the discrete substrate.
# Grass at carrying capacity + prey/predator seeded in central tiles → they graze and spread
# tile-to-tile via `move_t` diffusion. The discrete-representation counterpart of the field demo.
#
# Run from sim_lab/ :  julia --project=. scripts/grid_anim.jl

using SimLab
using AlgebraicPetri, DifferentialEquations, CairoMakie

const N = 12
world = grid_world(N)
net = stratify(assemble_local(ECOSYSTEM_RM; mobile = [:prey, :predator]), world)
println("net: ", ns(net), " species, ", nt(net), " transitions on ", N, "×", N, " grid")

# tile k → (row i, col j):  grid_world uses tile_id(i,j) = (i-1)*N + j
tilenum(nm) = parse(Int, string(nm)[2:end])
rc(k) = ((k - 1) ÷ N + 1, (k - 1) % N + 1)
function role_grid(u, role)
    M = zeros(N, N)
    for sp in 1:ns(net)
        nm = sname(net, sp); first(nm) == role || continue
        i, j = rc(tilenum(last(nm))); M[i, j] = u[sp]
    end
    M
end

# per-tile initial condition: grass at K everywhere; prey+predator seeded in a central 3×3 block
c = (N ÷ 2, N ÷ 2)
u0 = zeros(ns(net))
for sp in 1:ns(net)
    role = first(sname(net, sp)); i, j = rc(tilenum(last(sname(net, sp))))
    seeded = abs(i - c[1]) <= 1 && abs(j - c[2]) <= 1
    u0[sp] = role == :grass ? 5.0 : (seeded ? (role == :prey ? 0.8 : 0.4) : 0.0)
end

rates = Dict(:grass_growth => 1.0, :grass_crowding => 1.0/5.0, :grazing => 0.5, :prey_death => 0.5,
             :predation => 0.5, :predator_death => 0.5, :move_t => 0.5)
p = [rates[first(tname(net, t))] for t in 1:nt(net)]

T, nframes = 30.0, 80
sol = solve(ODEProblem(vectorfield(PetriNet(net)), u0, (0.0, T), p), Tsit5();
            saveat = range(0, T; length = nframes))
println("solved; frames = ", length(sol.u))

outdir = joinpath(@__DIR__, "outputs"); mkpath(outdir)
roles3 = [(:grass, :viridis), (:prey, :magma), (:predator, :plasma)]
crange = Dict(r => (0.0, maximum(maximum(role_grid(u, r)) for u in sol.u) + 1e-9) for (r, _) in roles3)

idx = Observable(1)
fig = Figure(size = (1000, 380))
for (ci, (r, cmap)) in enumerate(roles3)
    ax = CairoMakie.Axis(fig[1, ci], aspect = 1, yreversed = true,
        title = @lift string(r, "   t = ", round(sol.t[$idx], digits = 1)))
    hidedecorations!(ax)
    heatmap!(ax, @lift(role_grid(sol.u[$idx], r)), colormap = cmap, colorrange = crange[r])
end
mp4 = joinpath(outdir, "grid_anim.mp4")
record(fig, mp4, 1:nframes; framerate = 20) do i
    idx[] = i
end
println("saved animation -> ", mp4)

idx[] = round(Int, 0.5 * nframes)
frame = joinpath(outdir, "grid_anim_frame.png"); save(frame, fig)
println("saved frame -> ", frame)
