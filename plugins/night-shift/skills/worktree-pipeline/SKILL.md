---
name: worktree-pipeline
description: >-
  Run a queue of disjoint units of work through isolated git worktrees and land
  them: provision an environment per unit, dispatch an agent that owns it end
  to end, route green results to a serialized integration, then publish and
  tear down. Use for batch or unattended builds across many issues, parallel
  feature work that must not collide, or any run where each unit needs its own
  branch, port, and data store. Triggers include "work through these issues",
  "run the queue", "build these in parallel worktrees".
---

# worktree-pipeline

Takes a queue of disjoint units and runs them through isolated worktrees to a landed commit. This skill knows which agent handles which stage; the agents know nothing about the pipeline.

Everything project-specific comes from the adapter at `.claude/night-shift.md`. See `references/adapter.md` for the full spec, `references/adaptig-example.md` for a filled-in one, and `references/models-and-effort.md` for how model class and reasoning level resolve. This skill calls hooks by name and never contains a literal project command.

## Before the first dispatch

Check these once. Both are harness facts, and both fail quietly if you skip them:

- **Nested spawning must be on.** By default Claude Code withholds the `Agent` tool from every subagent, so a delegate cannot dispatch its planner, verifier, or fixer. Set `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` to at least `3` in settings.json. The deepest chain is delegate, then verifier, then browser-buddy. If it is off, stop and say so rather than dispatching delegates that will silently do everything themselves.
- **Run the adapter's `preflight` hook.** Fix or report what it flags before provisioning anything. A pipeline that starts against a broken environment produces failures that look like bad code.

Then confirm the queue is actually disjoint. Overlapping units are not a parallelism problem to solve later; they are a serialization decision to make now.

## Per unit

### 1. Provision

Create a worktree branched from the base branch, with its own dependencies, environment file, isolated data store, and a unique port. This is the skill's job, through the adapter's `provision` hook, because the delegate assumes it is already done. (The `Agent` tool's native `isolation: worktree` is not a substitute: it branches from the default branch and provisions nothing, no dependencies, no environment file, no data store, no port. Provisioning here is always the adapter's hook.)

Starting the dev server is the adapter's call, not a constant. Some `provision` hooks start it; others deliberately leave the port free, because at provision time the worktree is a copy of the base branch with nothing implemented, so a server started then is stale before anyone needs it and whoever builds the change starts it themselves with the `start` hook. Provision says which it did on its `SERVER=` line.

Record what provisioning printed: worktree path, port, data store name, and server state. Those are values you pass onward, never values an agent hardcodes or assumes.

If provisioning fails, the unit never enters a lane. Report it as an environment problem and move to the next unit.

### 2. Dispatch

Dispatch `night-shift-delegate` against that worktree, in the background, with the unit and the environment facts (see the contract below).

**Do not wait on it.** If a lane is free and disjoint work remains, start the next one. Waiting on a running unit while ready work sits idle is the single failure mode this pipeline exists to prevent.

### 3. Route the result

- `GREEN` goes to the integration queue.
- `BLOCKED` is parked with its reason and reported. It never stalls the other lanes, and it never gets retried in place without a change to its inputs.
- An environment failure returns to provisioning once, then parks.

Record the outcome as one line. Do not restate the delegate's report.

### 4. Integrate

Dispatch `night-shift-integrator`, **one at a time**, even when several units are ready. Integration is the one stage where parallelism produces conflicts instead of throughput.

The integrator lands a squash commit on the base branch and returns the SHA. It never pushes.

### 5. Publish and tear down

- Push according to the push policy: `after-each` (push right after each landing), `batched` (push once at the end of the run or at a stated milestone), or `never` (default; land locally and leave publishing to a human).
- Run the `teardown` hook: remove the worktree, drop its data store, free the port.
- Reconcile the task: confirm the ticket closed if the trailer said it would, note where it shipped, and update the tracking issue.

Pushing stays with the caller (the orchestrator), not with the integrator, so it stays serialized behind integration and only clean built state reaches the remote.

## Rules this skill enforces

- **Concurrency cap on live units, default 3, configurable.** It counts units, not processes, and it is low because each unit fans out its own subagents and browser instances. Three live units is already a dozen-plus processes and several headless browsers.
- **At most one integration at a time.**
- **Parallel lanes must be disjoint by file footprint.** Overlapping ready units run serially.
- **One stuck unit occupies at most one lane.** Never idle the others waiting on it.
- **Everything branches from the base branch**, and everything merges back to it.

## The contract every dispatched agent receives

Inject this boilerplate at dispatch, filled in with values. No agent should have to be told it twice, and no agent should ever hardcode any of it.

- **Worktree path.** "`cd` there first and confirm. All edits and version control commands stay inside it. Never touch the primary checkout."
- **Read the built repo's ground rules first.** If the worktree root carries an `AGENTS.md` or `CLAUDE.md`, read it before implementing. Dispatched agents do not inherit it automatically, and it is where the repo's non-negotiables live.
- **Read-only paths** it may consult (reference implementations, docs, an outer planning repo), passed as values.
- **The assigned port**, and what is on it, taken from provision's `SERVER=` line rather than assumed: either "the server is already running on it" or "the port is yours and unused; build and start it yourself with the `start` hook, and kill it when you are done."
- **Stop only the process it started, by its PID.** Never by name. `pkill -f "<start command>"` matches every lane's server, not just this one, so one unit's cleanup kills the app another unit is mid-verification against, which surfaces as an unreachable server and a `FAIL` written against working code. The port belongs to the unit; the process table is shared.
- **Its data store is its own.** Mutate it freely; reset with the `seed` hook. An unreachable data store is an environment failure to report, not evidence the work is broken.
- **Toolchain commands by hook name** (`typecheck`, `build`, `test`, `seed`, `start`), never as literal commands.
- **Browser work goes through `browser-buddy`**, with URL, credentials, and the exact journey. Agents do not drive browsers directly.
- **The required return shape** for that agent type.
- **The base branch**, so nothing branches from or merges to the wrong place.

## Dispatch record

Log every dispatch with its model and reasoning level, so a bad result traces to a downgrade:

```
#126 delegate model=opus effort=high lane=2 worktree=/w/issue-126 port=4102
```

Model overrides apply at dispatch; reasoning overrides do not (there is no dispatch-time effort parameter), and the haiku roles log `effort=n/a`. Never log a level that did not take effect. The full resolution rules live in `references/models-and-effort.md`.

## Without a subagent roster

Codex, Gemini, and any harness without agents run the same procedure in one context. This is a real fallback, not a stub, and it changes three things:

- **Drop the concurrency cap to 1.** One context cannot supervise parallel lanes, and pretending otherwise produces half-finished worktrees.
- **Context fills much faster**, because the reading, the implementation, and the verification all land in one window. Provision, build, verify, integrate, and tear down one unit completely before starting the next, and keep per-unit notes to a few lines.
- **Run the stages as phases of your own work**, in the same order, with the same separations of concern. In particular, still write the acceptance criteria down before implementing, and still check them explicitly afterward against the running app. The value of the split survives without the agents; what is lost is the isolation, not the discipline.

Everything else holds: worktree per unit, disjoint work only, one integration at a time, and the same contract values.
