# Tools — instruments

Interactive **readers of the harness** — *not* experiments. They run/visualize the engine live
(GLMakie needs a display, so run them locally from the REPL).

To be migrated here during triage:
- `dashboard.jl` — discrete-grid GLMakie dashboard over the stratified Petri model
  (`include` → `launch_dashboard()`).
- `gallery.jl` — compositional subsystem gallery: trendline panels + a selectable spatial grid
  (`include` → `launch_gallery()`).

A tool reads the harness; an experiment *is* a Scenario. If a thing produces a one-shot figure from a
fixed config, it's an experiment; if it's an interactive instrument you drive, it's a tool.
