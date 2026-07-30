# Models and reasoning levels

The canonical reference for how the night-shift roster resolves model class and reasoning level (`effort`). Agent definitions, skills, and the README point here instead of restating it.

## Model classes

Four classes, in order of capability: `fable`, `opus`, `sonnet`, `haiku`. The roster pins judgment-heavy roles (planner, fixer, delegate, orchestrator, researcher) on fable or opus at high, and everything else (grading, bulk reading, integration) on sonnet at medium. Nothing ships on haiku; it remains available as an override target. Any agent about to read a large corpus delegates the read to the scout, so expensive models spend context on judgment rather than on files.

Sonnet at medium is the floor for every role because the cheap tier did not turn out to be cheap. Measured on a browser-operation suite with planted defects and a known answer key, Haiku 4.5 cost the same per task as Sonnet at low ($0.188 against $0.185) while taking three times the turns and eight times the failed tool calls to get there, and it was the only class that fabricated evidence: it cited URLs it had never requested. A model that needs three times the steps gives back at the turn count whatever it saves on the per-token rate, and bulk reading is exactly where invented content is hardest to catch. The harness that produced those numbers is in `plugins/browser-buddy/eval/`.

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

Overriding a model does not carry a reasoning level with it. Dropping an agent to haiku does not lower its level so much as remove the control, which is one of the reasons no role ships there.

## Haiku takes no reasoning level

Haiku 4.5 does not take the `effort` parameter at all. No role ships on haiku, so this only matters when an adapter or a dispatch overrides one down to it: the override does not lower that role's reasoning level, it removes the control, and the dispatch record should log `effort=n/a` rather than carrying the frontmatter level forward. (This is from the documented model capability tables rather than a live capability query; if the harness simply drops the field on haiku, omitting it is still correct, just less load-bearing.)

## No role runs at low

Medium is the floor. Low scopes a model to exactly what was asked and makes it stop to ask rather than push through multi-step work, which is the opposite of what an unattended run needs. If a job feels cheap enough to want low, use a cheaper model at medium.

## The dispatch record

Every dispatch is logged with model and reasoning level together, so a bad result traces to a downgrade:

```
#126 planner  model=fable  effort=high     (frontmatter)
#126 delegate model=opus   effort=high     (frontmatter)
#126 scout    model=sonnet effort=medium   (frontmatter)
#126 integrator model=opus effort=high     (model override applied; level from override class default)
#126 verifier effort=high REQUESTED, NOT APPLIED (no dispatch-time effort lever); ran at medium
```

Record what actually happened, never what was asked for.

## When to say any of this to the user

Almost never. The dispatch record is a log; this file is a reference for decisions that
turn on it. Neither is a script to read aloud.

There is one trigger, and it is narrow: **the user asked for a reasoning level that
could not be applied.** Then say it once — what they asked for, what ran instead, and
that model is the lever that works at dispatch — and carry on.

Absent that request, a run that volunteers "reasoning cannot be overridden at dispatch"
is reporting a non-event as though it were a defect. Nobody asked, nothing failed, and
every run says it, so it reads as the tooling apologizing for itself on a fixed
schedule. Log the level that ran and move on.

## Cost basis

List prices, checked 2026-07-25. Verify before quoting.

| Model     | Input / output per Mtok                    | Output cost vs haiku |
| --------- | ------------------------------------------ | -------------------- |
| Fable 5   | $10 / $50                                  | 10x                  |
| Opus 5    | $5 / $25                                   | 5x                   |
| Sonnet 5  | $2 / $10 through 2026-08-31, then $3 / $15 | 2x, then 3x          |
| Haiku 4.5 | $1 / $5                                    | 1x                   |

Two levers, and they multiply: model class sets the per-token rate (a 10x spread across the roster), and reasoning level sets how many output tokens get spent on the same task (thinking tokens bill as output, so high can cost several times medium on identical work).

Dated facts to revisit rather than bake in: Sonnet 5 introductory pricing ends 2026-08-31 and rises 50%, which raises the cost of the verifier, scout, and integrator, now three of the eight roles; and prompt caching (cache reads cost about a tenth of input, against a 1.25x write premium on the 5-minute TTL) plus the batch API (50% off) are the two discounts that fit this workload, so an adapter should not make caching hard.
