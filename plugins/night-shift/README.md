# night-shift

Run a board of work unattended: triage what is open, build each unit in its own worktree, grade it against criteria it did not write for itself, land it, and report.

The package is a roster of small agents with narrow contracts, three skills any agent can invoke, and one command you talk to. Nothing in it names a project. Everything project-specific lives in a `.claude/night-shift.md` adapter in the consuming repo.

## Install

```
/plugin marketplace add arbiterhq/agent-skills
/plugin install night-shift@arbiterhq
```

Then, in the repo you want to run against, write `.claude/night-shift.md`. Start from `skills/worktree-pipeline/references/adapter.md` (the spec) and `references/adaptig-example.md` (a filled-in one).

### One setting is required

Claude Code withholds the `Agent` tool from subagents by default, so a delegate cannot dispatch its own planner, verifier, or fixer. Set the spawn depth in `settings.json`:

```json
{ "env": { "CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH": "3" } }
```

Three covers the deepest chain: delegate, then verifier, then browser-buddy. Use 4 if you dispatch the orchestrator as a subagent instead of running `/orchestrate`.

### Two soft dependencies

Neither is required, and both are degraded gracefully with a note in the return:

- **browser-buddy** (same marketplace) for behavior-level verification. Without it, the verifier drives the `agent-browser` skill directly.
- **artistic-vision** (same marketplace) for visual criteria. Without it, the verifier reads screenshots itself.

## Use it

```
/orchestrate any open bugs on github
/orchestrate #90 then #126 --cap 2 --push after-each
/orchestrate --base develop label:security
```

`/orchestrate` runs in the foreground, so it is a conversation. Interject at any time: add a task, drop one, reprioritize, redirect, or ask what is running.

Those three names are the package defaults. A repo is free to alias them to its own — Adaptig's run command is `/grind` — so when an agent points a user at a command, it names the one installed here rather than the default.

Stopping is two commands, and which one you type is the whole decision:

- `/drain` dispatches nothing further, lets in-flight units finish, integrates what comes back green, then reports and stops.
- `/abort` stops now, leaves every worktree and branch untouched, and reports exactly where each cancelled unit's work sits.

Both print the same closing summary shape, so the difference between them is what happened, not how it is reported.

## The roster

| Agent                      | Model  | Effort | One line                                         |
| -------------------------- | ------ | ------ | ------------------------------------------------ |
| `night-shift-orchestrator` | opus   | high   | holds the board, dispatches, never does the work |
| `night-shift-delegate`     | opus   | high   | owns one unit of work end to end                 |
| `night-shift-planner`      | fable  | high   | approach plus acceptance criteria                |
| `night-shift-researcher`   | opus   | high   | answers a question, read only                    |
| `night-shift-scout`        | haiku  | n/a    | bulk reading, returns extracts or pointers       |
| `night-shift-verifier`     | sonnet | medium | grades a change against the criteria             |
| `night-shift-fixer`        | fable  | high   | fixes a failed change against the criteria       |
| `night-shift-integrator`   | haiku  | n/a    | writes the squash message and lands the branch   |

Every agent is usable on its own. Ask the researcher a question, hand the planner a goal, point the scout at a log. The pipeline is one way to compose them, not the only one.

Three rules are in every definition: the final message is the return value (named fields, not prose); state what was actually done, including skipped steps and failures; never widen your own scope.

Names are prefixed because the pipeline dispatches by name and `planner` or `scout` would collide with whatever else a user has installed.

## The skills

- **`task-triage`** reads a whole GitHub issue board and returns a digest: a bucket per issue, an ordered queue, and disjoint clusters with file footprints. Never returns issue bodies. All `gh` calls sit in one section so another tracker can be swapped in.
- **`worktree-pipeline`** runs a queue of disjoint units through isolated worktrees: provision, dispatch, route, integrate one at a time, publish, tear down. Holds the concurrency rules and the contract every dispatched agent receives.
- **`task-tracking`** keeps the run's list in the built-in task list, one entry per unit with state, lane, and the model and effort of each dispatch. Files nothing to GitHub, on purpose.

Skills work in Codex and Gemini too. Agents and commands are Claude Code only, so both pipeline skills state what to do with no roster available: same procedure in one context, concurrency cap dropped to 1, with a warning that context fills faster. It is a real fallback, not a stub.

## Model classes and reasoning levels

Four classes, in order of capability: `fable`, `opus`, `sonnet`, `haiku`. Every agent that can declare a reasoning level declares one explicitly, so the resolved value is visible in the file rather than inferred.

Class defaults for reasoning level, applied when a definition says nothing: fable and opus high, sonnet medium. Haiku has no default because it takes no `effort` at all (see below).

Both values resolve independently, first match wins: dispatch-time value, then the adapter's override map, then the agent frontmatter, then the class default. Overriding a model does not carry a reasoning level with it, and dropping an agent to haiku does not lower its level so much as remove the control.

**No agent runs at `low`.** Medium is the floor. Low scopes a model to exactly what was asked and makes it stop to ask rather than push through multi-step work, which is the opposite of what an unattended run needs. If a job feels cheap enough to want low, use a cheaper model at medium.

### Where a reasoning level can be set

`effort` accepts `low`, `medium`, `high`, `xhigh`, or `max`, in two places:

- **Agent definition frontmatter**, which is where this roster pins its levels. It overrides the session effort.
- **Slash-command frontmatter**, which is how `/orchestrate`, `/drain`, and `/abort` pin the foreground level. All three sit at `high`, matching the orchestrator definition they adopt.

It is **not** a dispatch-time parameter. The `Agent` tool takes `model`, `subagent_type`, `isolation`, and `run_in_background`, and no effort. So a reasoning override has to be edited into the definition before the run, or set as the session level; when a run cannot apply a requested level it logs `effort=<X> REQUESTED, NOT APPLIED` rather than recording one that never took effect. Model is the lever that works at dispatch. (Workflow scripts are the one exception: `agent(prompt, {effort})` is a real per-call option there, but that is the workflow runner, not the `Agent` tool.)

**Haiku takes no reasoning level.** `night-shift-scout` and `night-shift-integrator` therefore carry no `effort` field, and their dispatch records log `effort=n/a`. A request to make either think harder is answered by overriding the model up to sonnet, which does take a level. This is from the documented model capability tables rather than a live capability query, so treat it as the reason the field is absent rather than as a tested assertion; if it turns out Claude Code simply drops the field on haiku, omitting it is still correct, just less load-bearing.

### Cost basis

List prices, checked 2026-07-25. Verify before quoting.

| Model     | Input / output per Mtok                    | Output cost vs haiku |
| --------- | ------------------------------------------ | -------------------- |
| Fable 5   | $10 / $50                                  | 10x                  |
| Opus 5    | $5 / $25                                   | 5x                   |
| Sonnet 5  | $2 / $10 through 2026-08-31, then $3 / $15 | 2x, then 3x          |
| Haiku 4.5 | $1 / $5                                    | 1x                   |

Two levers, and they multiply: model class sets the per-token rate, a 10x spread across the roster, and reasoning level sets how many output tokens get spent on the same task (thinking tokens bill as output, so high can cost several times medium on identical work).

The roster is built around that. Fable and opus at high do judgment that is expensive to get wrong: planning, fixing, owning a unit. The token-heavy jobs sit lower: grading on sonnet at medium, and reading and integrating on haiku, where the lever is the return cap rather than a reasoning level. Any agent about to read a large corpus delegates that read to the scout, so expensive models spend context on judgment rather than on files.

Two dated facts to revisit rather than bake in: Sonnet 5 introductory pricing ends 2026-08-31 and rises 50%, which raises the cost of the verifier, the only sonnet role in the roster; and prompt caching (cache reads cost about a tenth of input, against a 1.25x write premium on the 5-minute TTL) plus the batch API (50% off) are the two discounts that fit this workload, so an adapter should not make caching hard.

## Harness notes

- **Task tools need a foreground context.** Background subagents keep a reduced built-in tool set, and `TaskCreate` and friends are not in it. That is why `/orchestrate` is the entry point: run as a background subagent, the orchestrator cannot file entries and has to keep the board in its return instead.
- **Scout has no `Agent` tool** by frontmatter, so it structurally cannot recurse. Planner, researcher, verifier, and integrator have no `Edit` or `Write`, so read-only and grade-only roles are enforced rather than promised.
- **Skills are not preloaded into agents.** Agents invoke them through the `Skill` tool by name. Preloading a skill whose body says "dispatch a delegate" into an agent that is itself a delegate is how recursion starts.

## Where it came from

A decomposition of a single `grind` command that fused four things: a set of roles, a triage procedure, a dispatch and merge procedure, and one project's specifics. What changed:

1. One command instead of one command doing everything. `/orchestrate` is a conversation you steer; everything else is an agent or a skill, composable on its own.
2. `scout` is new, and exists so expensive models stop spending context on reading.
3. Roles are generic. No agent definition names a project, a package manager, a host, a database, or a port.
4. The fixed shape (plan, implement, verify, fix) is the delegate's default composition rather than a law.
5. Verifier, fixer, and integrator are addressable agents, not steps buried inside a build subagent.
6. The integrator writes the squash message from what actually changed.
7. Model and reasoning level are both data: declared in frontmatter, resolved independently.
8. Branch and push policy are parameters, not repo assumptions. Push defaults to `never`.
