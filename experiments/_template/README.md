# <Experiment Name>

**Status:** exploratory
**Question:** <the one-line question this experiment answers>

## Scenario

<What is configured on the engine — the currencies / pools / feeds, or what the swept axes are.
An experiment directory ↔ a Scenario instance, so describe that instance here.>

## Run

```
julia --project=. experiments/<id>/run.jl        # writes outputs/
```

**Gate:** <what makes this validated — e.g. conservation drift < 1e-6, or matches a closed-form result>

## Result

<The finding, with a pointer to outputs/. One or two sentences + the figure.>

## Notes

<Context, gotchas, and links to docs/ (journal, field guide, etc.).>
