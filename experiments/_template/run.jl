# Experiment: <name>
# Question: <one line>
# Run: julia --project=. experiments/<id>/run.jl
#
# Pattern: configure a Scenario (the forcings) → run/sweep the engine → assert a gate → write outputs.

using SimLab
# using CairoMakie   # uncomment if plotting

# --- Scenario: what is configured on the engine -----------------------------------------------
# C = Currency(:biomass, false)          # false = open (dissipates); true = closed (recycles)
# scn = Scenario([C],
#     [Pool(:grass,:producer,[1.0],0.0,0.0,0.02,[1.0],0.0),
#      Pool(:sheep,:consumer,[1.0],0.0,0.10,0.0,[0.0],0.0),
#      Pool(:detritus,:dead, [1.0],0.0,0.0,0.0,[0.0],0.0)],
#     [Feed(:grass,:sheep,0.3,1.0,0.5)],
#     :detritus, Dict(:grass=>[5.0],:sheep=>[1.0],:detritus=>[0.0]), [0.0])

# --- Run, or sweep ----------------------------------------------------------------------------
# sol, L = run_scenario(scn; T=600.0)
# M = sweep2(scn, ("axis1", vals1, (s,v)->set_feed(s,:grass,:sheep,:rate,v)),
#                 ("axis2", vals2, (s,v)->set_pool(s,:grass,:crowd,v)); living=[:grass,:sheep])

# --- Gate: what makes this a *validated* experiment -------------------------------------------
# cd, od = drifts(sol, L); @assert all(<(1e-6), cd) && all(<(1e-6), od)   # conservation
# or: @assert classify(sol, L, [:grass,:sheep]).surviving == [...known result...]

# --- Outputs (co-located) ---------------------------------------------------------------------
# out = joinpath(@__DIR__, "outputs"); mkpath(out)
# save(joinpath(out, "figure.png"), fig)

println("template — fill me in")
