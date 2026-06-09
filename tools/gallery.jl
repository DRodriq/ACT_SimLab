# Compositional subsystem gallery (interactive). View/simulate subsystems in isolation (with
# stubbed boundary forcings) and in composition, on the discrete Petri tile-graph, sharing one set
# of parameters and one clock.
#
#   • top row: a totals-over-time trendline per config (grass / grass+prey / prey+predator / full),
#     all sharing the time slider's current-frame dashed line — the compositional comparison.
#   • bottom: global rate/T/frames sliders + Run; a config+channel selector; and the selected
#     config's chosen species on the discrete grid (per-cell heatmap) at the current frame.
#
# GLMakie needs a display — run LOCALLY from the REPL:
#     julia --project=.
#     julia> include("scripts/gallery.jl")
#     julia> launch_gallery()
# (`build_gallery()` builds without opening a window — headless test.)

using GLMakie
using SimLab
using AlgebraicPetri, DifferentialEquations

const N = 12
const KVAL = 5.0

# config library: each a valid closed process set (+ stubs). "prey + predator" stubs prey's food
# with prey_birth (unlimited-food constant) → classic LV.
const CONFIGS = [
    (name = "grass",           procs = [:grass_growth, :grass_crowding],                                              mobile = Symbol[]),
    (name = "grass + prey",    procs = [:grass_growth, :grass_crowding, :grazing, :prey_death],                       mobile = [:prey]),
    (name = "prey + predator", procs = [:prey_birth, :predation, :predator_death],                                    mobile = [:prey, :predator]),
    (name = "full (RM)",       procs = [:grass_growth, :grass_crowding, :grazing, :prey_death, :predation, :predator_death], mobile = [:prey, :predator]),
]
const ROLE_COLOR = Dict(:grass => :seagreen, :prey => :firebrick, :predator => :darkorange)

tilenum(nm) = parse(Int, string(nm)[2:end])
rc(k) = ((k - 1) ÷ N + 1, (k - 1) % N + 1)
chan_sym(c)  = c == "grass" ? :grass : c == "prey" ? :prey : :predator
chan_cmap(c) = c == "grass" ? :viridis : c == "prey" ? :magma : :plasma
rate_dict(s) = Dict(:grass_growth => s[1], :grass_crowding => s[1] / KVAL, :grazing => s[2],
                    :prey_death => s[3], :predation => s[4], :predator_death => s[5],
                    :prey_birth => s[6], :move_t => s[7])
const DEFAULTS = [1.0, 0.5, 0.5, 0.5, 0.5, 0.6, 0.3]    # r, a, mₚ, b, m_q, prey_birth, move

struct Sys
    name::String
    net::Any
    rolemap::Dict{Symbol,Vector{Tuple{Int,Int,Int}}}
    proc::Vector{Symbol}
    u0::Vector{Float64}
    roles::Vector{Symbol}
end

function build_sys(cfg)
    net = stratify(assemble_local(cfg.procs; mobile = cfg.mobile), grid_world(N))
    roles = unique(first(sname(net, sp)) for sp in 1:ns(net))
    rolemap = Dict(r => [(sp, rc(tilenum(last(sname(net, sp))))...) for sp in 1:ns(net) if first(sname(net, sp)) == r]
                   for r in roles)
    proc = [first(tname(net, t)) for t in 1:nt(net)]
    c = (N ÷ 2, N ÷ 2); u0 = zeros(ns(net))
    for sp in 1:ns(net)
        role = first(sname(net, sp)); (i, j) = rc(tilenum(last(sname(net, sp))))
        seeded = abs(i - c[1]) <= 1 && abs(j - c[2]) <= 1
        u0[sp] = role == :grass ? KVAL : (seeded ? (role == :prey ? 0.8 : 0.4) : 0.0)
    end
    Sys(cfg.name, net, rolemap, proc, u0, sort(roles))
end

role_grid(s::Sys, u, role) = (M = zeros(N, N); haskey(s.rolemap, role) && for (sp, i, j) in s.rolemap[role]; M[i, j] = u[sp]; end; M)
role_total(s::Sys, u, role) = haskey(s.rolemap, role) ? sum(u[sp] for (sp, _, _) in s.rolemap[role]) : 0.0
run_sys(s::Sys, rates, T, nframes) = solve(ODEProblem(vectorfield(PetriNet(s.net)), s.u0, (0.0, T), [rates[p] for p in s.proc]),
                                           Tsit5(); saveat = range(0, T; length = nframes))

const SYSTEMS = [build_sys(c) for c in CONFIGS]    # built once at load

function build_gallery()
    fig = Figure(size = (1580, 980))
    topgl = fig[1, 1] = GridLayout()       # trendline panels
    botgl = fig[2, 1] = GridLayout()       # controls + spatial grid

    sg = SliderGrid(botgl[1, 1],
        (label = "r  (grass growth)", range = 0.2:0.05:2.0,    startvalue = 1.0),
        (label = "a  (grazing)",      range = 0.1:0.05:1.5,    startvalue = 0.5),
        (label = "mₚ (prey death)",   range = 0.1:0.05:1.5,    startvalue = 0.5),
        (label = "b  (predation)",    range = 0.1:0.05:1.5,    startvalue = 0.5),
        (label = "m_q (pred death)",  range = 0.1:0.05:1.5,    startvalue = 0.5),
        (label = "prey_birth (LV food)", range = 0.1:0.05:1.5, startvalue = 0.6),
        (label = "move (diffusion)",  range = 0.0:0.05:2.0,    startvalue = 0.3),
        (label = "T  (sim time)",     range = 10.0:10.0:400.0, startvalue = 40.0),
        (label = "frames",           range = 50:25:600,       startvalue = 150),
        tellheight = false)

    ctrl = botgl[1, 2] = GridLayout()
    Label(ctrl[1, 1], "config", tellwidth = false)
    cfgmenu  = Menu(ctrl[2, 1], options = [c.name for c in CONFIGS], default = CONFIGS[end].name)
    Label(ctrl[3, 1], "channel", tellwidth = false)
    chanmenu = Menu(ctrl[4, 1], options = ["grass", "prey", "predator"], default = "prey")
    runbtn   = Button(ctrl[5, 1], label = "▶  Run simulation")

    axg = GLMakie.Axis(botgl[1, 3], aspect = 1, yreversed = true,
        title = @lift string($(cfgmenu.selection), " — ", $(chanmenu.selection)))
    hidedecorations!(axg)

    tsl = Slider(fig[3, 1], range = 0.0:0.005:1.0, startvalue = 0.4)
    Label(fig[4, 1], "← scrub time →", tellwidth = false)

    sols  = Observable([run_sys(s, rate_dict(DEFAULTS), 40.0, 150) for s in SYSTEMS])
    nf    = @lift length(($sols)[1].u)
    frame = @lift clamp(round(Int, $(tsl.value) * ($nf - 1)) + 1, 1, $nf)

    trendaxes = GLMakie.Axis[]
    for (i, s) in enumerate(SYSTEMS)
        ax = GLMakie.Axis(topgl[1, i], title = s.name, xlabel = "t", ylabel = i == 1 ? "total" : "")
        push!(trendaxes, ax)
        for r in s.roles
            lines!(ax, @lift(($sols)[i].t), @lift([role_total(s, u, r) for u in ($sols)[i].u]),
                   color = ROLE_COLOR[r], label = string(r))
        end
        vlines!(ax, @lift(($sols)[i].t[$frame]), color = (:black, 0.6), linestyle = :dash)
        axislegend(ax; position = :rt, labelsize = 9)
    end

    ci   = @lift findfirst(c -> c.name == $(cfgmenu.selection), CONFIGS)
    grd  = @lift role_grid(SYSTEMS[$ci], ($sols)[$ci].u[$frame], chan_sym($(chanmenu.selection)))
    crng = @lift (0.0, maximum(maximum(role_grid(SYSTEMS[$ci], u, chan_sym($(chanmenu.selection))))
                               for u in ($sols)[$ci].u) + 1e-9)
    plt  = heatmap!(axg, grd, colormap = @lift(chan_cmap($(chanmenu.selection))), colorrange = crng)
    Colorbar(botgl[1, 4], plt)

    on(runbtn.clicks) do _
        s = [sg.sliders[i].value[] for i in 1:7]
        T = sg.sliders[8].value[]; nframes = round(Int, sg.sliders[9].value[])
        @info "Run: solving all configs…" T nframes
        try
            sols[] = [run_sys(sys, rate_dict(s), T, nframes) for sys in SYSTEMS]
            foreach(reset_limits!, trendaxes)        # refit axes to the new run's time span + scale
            @info "Run: done — scrub the time slider"
        catch e
            @warn "Run failed (try gentler parameters)" exception = e
        end
    end
    fig
end

launch_gallery() = (GLMakie.activate!(); display(build_gallery()); nothing)
