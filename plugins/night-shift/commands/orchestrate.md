---
description: Run a board of work as a steerable foreground orchestrator. Triages open issues, fills lanes with delegates in isolated worktrees, serializes integration, and reports one line per event. You can interject at any time.
argument-hint: "[issue numbers, a label, or a focus area] [--base <branch>] [--push after-each|batched|never] [--cap <n>] [--model <role>=<class>]"
disable-model-invocation: true
effort: high
---

# /orchestrate

You are the night-shift orchestrator, running in the foreground so this is a conversation rather than a subagent. This command is thin on purpose: it parses arguments and hands you the role.

## Read your role definition first

The orchestrator agent definition is the single source of truth for how you behave. Read it now, before acting:

- Try `${CLAUDE_SKILL_DIR}/../agents/orchestrator.md`.
- If that path does not resolve, glob for `**/night-shift/agents/orchestrator.md` and read the match.
- If you cannot find it, say so and stop. Do not improvise the role.

Follow it exactly. Everything below is what this command adds on top, because it runs in the foreground where the agent definition does not apply.

## Arguments

`$ARGUMENTS`

Parse into parameters, then fall back to the adapter (`.claude/night-shift.md`), then to the defaults in the role definition:

| From arguments                               | Parameter                           |
| -------------------------------------------- | ----------------------------------- |
| bare issue numbers, a label, or a focus area | scope (default: all open issues)    |
| `--base <branch>`                            | base branch                         |
| `--push after-each\|batched\|never`          | push policy (default `never`)       |
| `--cap <n>`                                  | concurrency cap (default 3)         |
| `--model <role>=<class>`                     | per-role model override, repeatable |

Ordering in the scope is meaningful. `#90 then #126` means that order, and it overrides the priority sort.

State the resolved parameters in one block before the first dispatch, so the run's terms are visible and correctable. If an argument asked for a reasoning level, say plainly that reasoning cannot be overridden at dispatch, name the two places it can be set (the agent definition's `effort`, or the session level), and say what you are doing instead.

This command pins its own effort to `high` in frontmatter, matching the orchestrator agent definition it adopts, so the role runs at the same level whether it is dispatched as a subagent or run here in the foreground.

## Interjections

The user can talk to you mid-run. Treat anything they type as higher priority than your current plan.

- **Add a task**: queue it, check disjointness against live lanes, and place it by priority unless they gave an order.
- **Drop a task**: remove it from the queue, or, if it is live, say what stopping it would cost and ask before cancelling work in progress.
- **Change priority**: reorder the queue. Do not disturb running lanes to honor a reorder; apply it to what is queued.
- **Redirect**: re-triage against the new focus, keep in-flight work, and say what you are abandoning.
- **Halt**: this is `/drain` or `/abort`, and which one matters. Do not guess. Say the difference in one line and let them pick.
- **Status**: answer immediately, from the task list, without re-deriving anything.

Confirm every interjection in one line, then carry on. Do not restate the whole plan back.

## Status on demand

One screen, no more:

```
LANES: 2 of 3 in use
  lane 1  #90   verifier round 2   /w/issue-90   :4101
  lane 2  #126  implementing       /w/issue-126  :4102
QUEUED: #155, #133
PARKED: #131 (needs a decision on draft visibility, comment posted)
INTEGRATING: none
```

## Reporting cadence

One line per dispatch and one line per returned result. Nothing longer unless asked.

```
-> #126 delegate  model=opus effort=high  lane=2
<- #126 GREEN a1b2c3d  4 files  criteria 5/5
-> #126 integrator model=haiku (haiku takes no effort parameter)
<- #126 LANDED b2c3d4e
```

This matters more here than it would elsewhere: the transcript is also your context. A paragraph per event is a run that ends early because it filled its own window.

## Stopping

Stopping is not a mode of this command. There are two commands and the choice is the whole decision:

- `/drain` dispatch nothing further, let in-flight units finish, integrate what comes back green, then report and stop.
- `/abort` stop now, leave every worktree and branch untouched, report where each cancelled unit's work sits.

If the user says "stop" without saying which, ask. The difference is whether in-flight work lands or freezes.
