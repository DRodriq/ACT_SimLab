module Viz

using CairoMakie
using ..Schema

export plot_aggregate, plot_phase, animate_grid

function plot_aggregate(sol, n_tiles)
    times = sol.t
    # Sum across tiles. Assuming state layout: [tile1_prey, tile1_pred, tile2_prey, ...]
    prey_total = [sum(sol(t)[1:2:end]) for t in times]
    pred_total = [sum(sol(t)[2:2:end]) for t in times]
    fig = Figure()
    ax = Axis(fig[1,1], xlabel="time", ylabel="population")
    lines!(ax, times, prey_total, label="prey")
    lines!(ax, times, pred_total, label="predator")
    axislegend(ax)
    fig
end

function plot_phase(sol)
    times = sol.t
    prey_total = [sum(sol(t)[1:2:end]) for t in times]
    pred_total = [sum(sol(t)[2:2:end]) for t in times]
    fig = Figure()
    ax = Axis(fig[1,1], xlabel="prey", ylabel="predator")
    lines!(ax, prey_total, pred_total)
    fig
end

function animate_grid(sol, world, n, filename="grid.mp4")
    times = sol.t
    fig = Figure()
    ax = Axis(fig[1,1], aspect=DataAspect(), title="prey density")
    grid = Observable(zeros(n, n))
    hm = heatmap!(ax, grid, colormap=:viridis)
    Colorbar(fig[1,2], hm)

    record(fig, filename, eachindex(times); framerate=20) do i
        state = sol.u[i]
        for tile in 1:n*n
            i_row = ((tile-1) ÷ n) + 1
            j_col = ((tile-1) % n) + 1
            grid[][i_row, j_col] = state[2*(tile-1) + 1]  # prey
        end
        notify(grid)
    end
end

end