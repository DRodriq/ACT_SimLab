# Tools — instruments

Readers of the harness — *not* experiments. (A tool reads a `Scenario`; an experiment *is* one.)

- **`composition.jl`** — `composition_graph(scn, path; title)`: renders any `Scenario`'s food-web
  structure (pools laid out by trophic level, feeds as solid "eats" arrows, detritus as the dashed
  sink). Used by experiments to emit a composition graph next to their dynamics. CairoMakie, headless.
- **`dashboard.jl`** — discrete-grid GLMakie dashboard over the stratified Petri model
  (`include` → `launch_dashboard()`). Needs a display; run locally from the REPL.
- **`gallery.jl`** — compositional subsystem gallery: trendline panels + a selectable spatial grid
  (`include` → `launch_gallery()`). Needs a display.
