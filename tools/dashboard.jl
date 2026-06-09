# Interactive GLMakie dashboard — DISCRETE grid view of the stratified Petri tile-graph model.
# Shows grass / prey / predator simultaneously as per-cell heatmaps (cell-based: flat color per
# tile, no interpolation), each with a totals-over-time trendline marked at the current frame.
# Controls: rate + diffusion sliders, simulation-time (T) and frame-count sliders, a Run button,
# and a fractional time slider to scrub.
#
# GLMakie needs a display — run LOCALLY from the REPL:
#     julia --project=.
#     julia> include("scripts/dashboard.jl")
#     julia> launch_dashboard()
# (`build_dashboard()` builds without opening a window — headless test.)

using GLMakie
using SimLab
using AlgebraicPetri, DifferentialEquations

const N = 12
const NET  = stratify(assemble_local(ECOSYSTEM_RM; mobile = [:prey, :predator]), grid_world(N))
const VF   = vectorfield(PetriNet(NET))
const PROC = [first(tname(NET, t)) for t in 1:nt(NET)]

tilenum(nm) = parse(Int, string(nm)[2:end])
rc(k) = ((k - 1) ÷ N + 1, (k - 1) % N + 1)
const ROLEMAP = Dict(r => [(sp, rc(tilenum(last(sname(NET, sp))))...)
                           for sp in 1:ns(NET) if first(sname(NET, sp)) == r]
                     for r in (:grass, :prey, :predator))
role_grid(u, role) = (M = zeros(N, N); for (sp, i, j) in ROLEMAP[role]; M[i, j] = u[sp]; end; M)
role_total(u, role) = sum(u[sp] for (sp, _, _) in ROLEMAP[role])

const KVAL = 5.0
const U0 = let u = zeros(ns(NET)), c = (N ÷ 2, N ÷ 2)
    for sp in 1:ns(NET)
        role = first(sname(NET, sp)); (i, j) = rc(tilenum(last(sname(NET, sp))))
        seeded = abs(i - c[1]) <= 1 && abs(j - c[2]) <= 1
        u[sp] = role == :grass ? KVAL : (seeded ? (role == :prey ? 0.8 : 0.4) : 0.0)
    end
    u
end

run_sim(rates, T, nframes) = solve(ODEProblem(VF, U0, (0.0, T), [rates[PROC[t]] for t in 1:nt(NET)]),
                                   Tsit5(); saveat = range(0, T; length = nframes))
rate_dict(s) = Dict(:grass_growth => s[1], :grass_crowding => s[1] / KVAL, :grazing => s[2],
                    :prey_death => s[3], :predation => s[4], :predator_death => s[5], :move_t => s[6])

const PANELS = [(:grass, :viridis, :seagreen), (:prey, :magma, :firebrick), (:predator, :plasma, :darkorange)]

function build_dashboard()
    fig = Figure(size = (1480, 840))

    sg = SliderGrid(fig[1, 1],
        (label = "r  (grass growth)", range = 0.2:0.05:2.0,    startvalue = 1.0),
        (label = "a  (grazing)",      range = 0.1:0.05:1.5,    startvalue = 0.5),
        (label = "mₚ (prey death)",   range = 0.1:0.05:1.5,    startvalue = 0.5),
        (label = "b  (predation)",    range = 0.1:0.05:1.5,    startvalue = 0.5),
        (label = "m_q (pred death)",  range = 0.1:0.05:1.5,    startvalue = 0.5),
        (label = "move (diffusion)",  range = 0.0:0.05:2.0,    startvalue = 0.5),
        (label = "T  (sim time)",     range = 10.0:10.0:400.0, startvalue = 40.0),
        (label = "frames",           range = 50:25:600,       startvalue = 150),
        tellheight = false)
    runbtn = Button(fig[2, 1], label = "▶  Run simulation", tellwidth = false)
    tsl = Slider(fig[3, 1:4], range = 0.0:0.005:1.0, startvalue = 0.4)
    Label(fig[4, 1:4], "← scrub time →", tellwidth = false)

    sol  = Observable(run_sim(rate_dict([1.0, 0.5, 0.5, 0.5, 0.5, 0.5]), 40.0, 150))
    nf   = @lift length(($sol).u)
    fidx = @lift clamp(round(Int, $(tsl.value) * ($nf - 1)) + 1, 1, $nf)
    curt = @lift ($sol).t[$fidx]

    for (ci, (role, cmap, lcol)) in enumerate(PANELS)
        axh = GLMakie.Axis(fig[1, ci+1], aspect = 1, yreversed = true, title = string(role))
        hidedecorations!(axh)
        crng = @lift (0.0, maximum(maximum(role_grid(u, role)) for u in ($sol).u) + 1e-9)
        heatmap!(axh, @lift(role_grid(($sol).u[$fidx], role)), colormap = cmap, colorrange = crng)

        axt = GLMakie.Axis(fig[2, ci+1], title = string(role, " total"), xlabel = "t", height = 150)
        lines!(axt, @lift(($sol).t), @lift([role_total(u, role) for u in ($sol).u]), color = lcol)
        vlines!(axt, curt, color = (:black, 0.6), linestyle = :dash)
    end

    on(runbtn.clicks) do _
        rates = rate_dict([sg.sliders[i].value[] for i in 1:6])
        T = sg.sliders[7].value[]; nframes = round(Int, sg.sliders[8].value[])
        @info "Run: solving…" T nframes
        try
            sol[] = run_sim(rates, T, nframes)
            @info "Run: done ($(nframes) frames over t∈[0,$(T)]) — scrub to replay"
        catch e
            @warn "Run failed (try gentler parameters)" exception = e
        end
    end
    fig
end

launch_dashboard() = (GLMakie.activate!(); display(build_dashboard()); nothing)
