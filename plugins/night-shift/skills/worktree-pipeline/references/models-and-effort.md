# Models and reasoning levels

The canonical reference for how the night-shift roster resolves model class and reasoning level (`effort`). Agent definitions, skills, and the README point here instead of restating it.

## Model classes

Four classes, in order of capability: `fable`, `opus`, `sonnet`, `haiku`. The roster pins judgment-heavy roles (planner, fixer, delegate, orchestrator, researcher) on fable or opus at high, grading on sonnet at medium, and bulk reading and integration on haiku, where the cost control is a reading or return cap rather than a reasoning level. Any agent about to read a large corpus delegates the read to the scout, so expensive models spend context on judgment rather than on files.

## Where a reasoning level can be set

`effort` accepts `low`, `medium`, `high`, `xhigh`, or `max`, in exactly two places:

- **Agent definition frontmatter**, which is where this roster pins its levels. It overrides the session effort.
- **Slash-command frontmatter**, which is how the run, drain, and halt commands pin the foreground level for their turn.

It is **not** a dispatch-time parameter. The `Agent` tool takes `model`, `subagent_type`, `isolation`, and `run_in_background`, and no effort. A reasoning override therefore has to be edited into the agent definition before the run, or set as the session effort level; both are the user's call. When a run cannot apply a requested level, it logs `effort=<X> REQUESTED, NOT APPLIED (no dispatch-time effort lever); ran at <Y> from frontmatter` rather than recording a level that never took effect. Model is the lever that works at dispatch; reach for it first.

(Workflow scripts are the one exception: `agent(prompt, {effort})` is a real per-call option there, but that is the workflow runner, not the `Agent` tool.)

## Resolution order

Model and reasoning level resolve independently, first match wins:

1. an explicit model passed at dispatch (including flags to the foreground orchestrator command)
2. the adapter's `overrides` map, read once at the top of the run
3. the agent definition frontmatter
4. the class default for reasoning level: fable and opus high, sonnet medium; haiku has none

Overriding a model does not carry a reasoning level with it. Dropping an agent to haiku does not lower its level so much as remove the control.

## Haiku takes no reasoning level

`night-shift-scout` and `night-shift-integrator` carry no `effort` field because Haiku 4.5 does not take the parameter. Dispatch records log them as `effort=n/a`. A request to make either think harder is answered by overriding the model up to sonnet, which does take a level. (This is from the documented model capability tables rather than a live capability query; if the harness simply drops the field on haiku, omitting it is still correct, just less load-bearing.)

## No role runs at low

Medium is the floor. Low scopes a model to exactly what was asked and makes it stop to ask rather than push through multi-step work, which is the opposite of what an unattended run needs. If a job feels cheap enough to want low, use a cheaper model at medium.

## The dispatch record

Every dispatch is logged with model and reasoning level together, so a bad result traces to a downgrade:

```
#126 planner  model=fable  effort=high     (frontmatter)
#126 delegate model=opus   effort=high     (frontmatter)
#126 scout    model=sonnet effort=medium   (model override applied)
#126 integrator model=haiku effort=n/a     (haiku takes no effort parameter)
#126 verifier effort=high REQUESTED, NOT APPLIED (no dispatch-time effort lever); ran at medium
```

Record what actually happened, never what was asked for.

## Cost basis

List prices, checked 2026-07-25. Verify before quoting.

| Model     | Input / output per Mtok                    | Output cost vs haiku |
| --------- | ------------------------------------------ | -------------------- |
| Fable 5   | $10 / $50                                  | 10x                  |
| Opus 5    | $5 / $25                                   | 5x                   |
| Sonnet 5  | $2 / $10 through 2026-08-31, then $3 / $15 | 2x, then 3x          |
| Haiku 4.5 | $1 / $5                                    | 1x                   |

Two levers, and they multiply: model class sets the per-token rate (a 10x spread across the roster), and reasoning level sets how many output tokens get spent on the same task (thinking tokens bill as output, so high can cost several times medium on identical work).

Dated facts to revisit rather than bake in: Sonnet 5 introductory pricing ends 2026-08-31 and rises 50%, which raises the cost of the verifier, the only sonnet role in the roster; and prompt caching (cache reads cost about a tenth of input, against a 1.25x write premium on the 5-minute TTL) plus the batch API (50% off) are the two discounts that fit this workload, so an adapter should not make caching hard.
