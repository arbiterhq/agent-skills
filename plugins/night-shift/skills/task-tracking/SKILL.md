---
name: task-tracking
description: >-
  Maintain a run's list of work in the built-in task list: one entry per unit,
  with state, lane, and the model and reasoning level used for each dispatch.
  Use during a multi-unit run so a returned result costs one write instead of a
  paragraph of context, and so "what is running right now" can be answered
  without re-deriving it. Files nothing to the issue tracker.
---

# task-tracking

The run's working memory. One entry per unit of work, updated on every transition, and answerable cheaply when someone asks what is happening.

This skill tracks a run. It does not write to GitHub. That boundary is the point: durable knowledge belongs on the ticket and gets there through `task-triage`'s hygiene rules, while run bookkeeping stays here and dies with the run.

## Where the list comes from

Either of two ways:

1. **The goals you were given.** `/orchestrate any open bugs on github`, or `#90 then #126`, or a focus area. Take them as stated, including any ordering the user implied.
2. **Your own reading of task state**, when no goals were named. Work out what should be worked on from the `task-triage` digest, what is already in flight (worktrees, branches, unpushed commits), and what is blocked. Prefer finishing in-flight work over starting new work.

Either way the list is derived at the start of the run and does not carry over to the next one. Neither the run nor the list is durable, and neither needs to be: git, the tracker, and the worktree list are what survive.

## The entry

One per unit of work, carrying:

- **id**: the issue number or unit identifier
- **state**: `queued`, `dispatched`, `returned-green`, `parked`, `integrated`, `pushed`, `reconciled`
- **lane**: which lane it occupies, or none
- **dispatches**: one line each, with the model and the reasoning level actually used
- **footprint**: the files it claims, so disjointness can be checked without re-deriving it
- **note**: one line, the current reason or the last outcome

Use `TaskCreate` to open entries and `TaskUpdate` on every transition. A returned result is one write, not a paragraph in the caller's context.

## Transitions

```
queued -> dispatched         (lane assigned, worktree and port recorded)
dispatched -> returned-green (delegate returned GREEN with a SHA)
dispatched -> parked         (BLOCKED, environment failure, or needs a decision)
returned-green -> integrated (integrator landed a squash commit)
integrated -> pushed         (push policy allowed it)
pushed -> reconciled         (ticket closed or noted, worktree torn down)
parked -> queued             (only when its inputs changed; never a blind retry)
```

Record the transition, not the story. "returned-green, a1b2c3d" is the entry; the reasoning behind it lived in the delegate's context and can stay there.

## Dispatch records carry model and reasoning together

Every dispatch line records both, because a bad result usually traces to a downgrade:

```
#126 planner  model=fable  effort=high     (frontmatter)
#126 delegate model=opus   effort=high     (frontmatter)
#126 scout    model=sonnet effort=medium   (model override applied)
#126 integrator model=haiku effort=n/a     (haiku takes no effort parameter)
#126 verifier effort=high REQUESTED, NOT APPLIED (no dispatch-time effort lever); ran at medium
```

The last two lines matter. Model overrides can be applied at dispatch; reasoning overrides cannot, because the `Agent` tool has no effort parameter, and on haiku there is no effort parameter to apply in the first place. Record what actually happened, never what was asked for.

## Answering the status question

Keep the list good enough that "what is running?" is a read, not a re-derivation. A status answer is one screen:

- lanes in use, and the unit in each
- state per unit, one line
- what is queued next
- what is parked, and why

If answering that requires re-reading git or the tracker, the list was not maintained. Fix the list.

## Not this skill's job

- **Writing to GitHub.** Not a comment, not a label, not a close. That is `task-triage`.
- **Deciding what to work on.** That is triage plus the caller.
- **Holding detail.** If an entry needs a paragraph, the paragraph belongs in the agent's return or on the ticket, and the entry gets the one-line version.

Worth writing to a ticket instead of here: an ordering constraint ("do not land #126 before #90"), or a dead end already explored ("tried this with webcontainers, did not work"). A future run cannot derive those from code or issue state. It can derive everything in this list.

## Without the task tools

Background subagents keep a reduced built-in tool set, and the task tools are not in it. Codex and Gemini have no task list at all. In either case:

- Keep the same list in a single compact block you rewrite each turn, in the transcript or in a scratch file. Same fields, same states, same transitions.
- Rewrite it in full on each update rather than appending deltas, so the current state is always readable in one place.
- Say once, at the start, that you are tracking this way. A caller who thinks entries are being filed and finds nothing afterward has lost the run's history.
