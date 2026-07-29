---
name: task-triage
description: >-
  Read a whole GitHub issue board and return a compact plan: a bucket per issue
  (BUILD, FEEDBACK, HOLD, EPIC), an ordered build queue, and disjoint clusters
  that can run in parallel. Use before starting a batch of work, when deciding
  what to work on next across many open issues, or at the start of an
  unattended run. Triggers include "triage the open issues", "what should we
  work on", "plan the board", "sort these tickets". Returns a digest, never
  issue bodies, so the caller's context stays small.
context: fork
background: false
---

# task-triage

Reads the whole board so the caller does not have to. The output is a digest: buckets, an ordered queue, and clusters. Issue bodies never come back.

This is deliberately the first action of any run. A caller that reads sixty issue bodies itself has spent its context before doing anything. On Claude Code this skill runs forked in its own context (`context: fork`), so even this procedure never enters the caller's window; the digest is the only thing that returns, and your final message must be exactly that digest.

## Inputs

- **Scope** (optional): issue numbers, a label, or a focus area. Default is everything open. Scope as invoked: "$ARGUMENTS" (empty means everything open).
- **Adapter**: `.claude/night-shift.md` in the consuming repo. Keys read here: `repo`, `priority_order`, `references`, `prior_art`, `overrides`. A missing adapter is not fatal for triage; a missing `repo` is, since there is no board to read.

## Use a scout for the reading pass

When a subagent roster is available, dispatch `night-shift-scout` for the reading pass: hand it the issue list and the question ("bucket each of these, quote only the deciding lines"), and work from its `EXTRACT`. This is the difference between a triage that costs a few thousand tokens of context and one that costs fifty thousand.

**Apply the adapter's `overrides` for the scout role to this dispatch.** Triage is usually the first dispatch of a run, so it is the one most often sent at a default model while the adapter was asking for a higher one. Read `overrides` before dispatching, not after, and log the model you actually used.

**Without a subagent roster** (Codex, Gemini, or any harness without agents), run the same procedure in one context. It works, with two adjustments worth stating out loud:

- Context fills faster, so read in batches and write each batch's buckets into the digest before reading the next. Do not hold sixty issue bodies at once.
- Drop the concurrency cap to 1 for whatever runs after this. One context cannot supervise parallel lanes.

## Step 1: enumerate

All tracker calls live in this section, so a different tracker can be swapped in by rewriting only this block. Everything after it works on the enumerated list, not on GitHub.

```bash
# The board, scoped or not
gh -R <repo> issue list --state open --limit 200 --json number,title,labels,updatedAt
gh -R <repo> issue list --state open --label <label> --json number,title,labels

# One issue, body and comments together, as a unit
gh -R <repo> issue view <n> --comments

# Ticket hygiene, one comment, once
gh -R <repo> issue comment <n> --body-file <file>
```

Honor the scope argument here rather than filtering later.

## Step 2: read the body and the comments together

**Hard rule: read each issue's body and its comments as one unit. Never the body without its comments, never the comments as a replacement for the body.**

The body is the spec. Comments amend it: decisions, approvals, answers, reversals. Miss a comment and you rebuild decided work, treat unblocked work as blocked, or re-ask an answered question. Ignore the body and you build a ghost of the real ask.

**Comment count is not a staleness signal.** An issue filed ten minutes ago with zero comments is fully current and its body stands on its own. A heavily commented issue can be perfectly current too. What actually makes a body stale is something outside the ticket:

- code already on disk that implements or supersedes it
- a superseding issue, epic, or sibling
- a decision recorded outside the tracker (a meeting, a contract, a design doc)
- prior art that already defines the behavior

Judge staleness against those, not against the thread.

## Step 3: bucket

Sort every issue into exactly one bucket:

- **`BUILD`**: a clear, self-contained change that needs no stakeholder decision. These feed the pipeline.
- **`FEEDBACK`**: needs a product decision, is a spec reconciliation, or asks a question. Do not implement.
- **`HOLD`**: destructive, outward-facing, or hard to reverse (data migrations, DNS, deploys, anything touching real users). Do not auto-execute. Write the runbook and the decisions needed, then wait for explicit approval.
- **`EPIC`**: tracking only. Not work in itself; note which children it covers.

**Before filing anything as `FEEDBACK`, check whether prior art already answers the question.** Most "design questions" on a board like this are already answered by an existing implementation whose behavior is the baseline. If the reference answers it, it is a `BUILD` that starts from that baseline, not a `FEEDBACK`. Escalate only what the references and docs genuinely do not answer, or a divergence from baseline big enough to need the owner's call.

Discernment is the core of this skill. Default to acting: most tickets can be done well from prior art plus the code. Ask when guessing risks meaningful rework, a wrong product decision, an irreversible action, or a data-integrity mistake. Do not ask for things you can reasonably decide.

## Step 4: order the build queue

Security first, then bugs, then features. A broken, leaking, or regressed behavior jumps ahead of anything that adds new capability. Use the adapter's `priority_order` when it defines one; otherwise use that default.

This orders the queue. It does not override the `HOLD` guardrail: security work that is production-sensitive still routes to `HOLD` rather than jumping the queue into an automated run.

## Step 5: cluster into disjoint groups

Group the `BUILD` queue into clusters that do not touch the same files, and give each a rough file footprint. The caller runs clusters in parallel and runs overlapping work serially, so the footprint is the whole basis of that decision. Be honest about reach: an optimistic footprint produces two agents editing the same file in two worktrees, and one of them loses.

When file overlap is not obvious from the issues, dispatch a scout to check rather than guessing.

## Ticket hygiene

Enforced by this skill, not left to the caller:

- **Never post a redundant comment.** Read the thread first. Do not restate what the owner already said, re-announce a recorded decision, or re-ask an answered question. A comment is justified only when it adds new information.
- **When you need input, ask once.** One comment carrying your assessment, what prior art says (or that none exists), a concrete recommendation, and exactly what input would unblock it. End it with a line marking it as automated, for example: `posted automatically by task-triage; no further comments on this ticket until someone replies.`
- **Then stop.** Do not comment on that ticket again until someone responds. If a later pass finds the thread now answers the question, skip the comment entirely and start the work.
- `FEEDBACK` and `HOLD` issues stay open with their one comment. Do not close them.
- File new issues for follow-ups you discover. Durable knowledge belongs on the ticket: an ordering constraint ("do not land #126 before #90"), or a dead end already explored ("tried this with webcontainers, did not work"). Run bookkeeping does not belong in a comment thread; that is the `task-tracking` skill's job and it stays out of GitHub.

## Return: a digest, not a board

```
BUCKETS:
  #90  BUILD     bug       auth cookie dropped on subdomain
  #126 BUILD     feature   document preview pane
  #131 FEEDBACK  question  asked: which roles see drafts (recommended: admin only)
  #140 HOLD      migration backfills org_id, needs approval
  #77  EPIC      tracking  covers #90, #126

QUEUE (ordered): #90, #155, #126, #133

CLUSTERS (disjoint, parallel-safe):
  A: #90, #155   footprint: src/auth/**, src/middleware/session.ts
  B: #126        footprint: src/apps/preview/**, src/components/Pane.tsx
  C: #133        footprint: docs/**, src/config/flags.ts

ALREADY_SHIPPED: #118 (implemented in a1b2c3d, ticket still open)
COMMENTED: #131 (one comment posted)
NOTES: #126 blocked behind #90 by an ordering constraint recorded on the ticket
```

Return that and nothing else. No issue bodies, no thread summaries, no restated specs. If the caller needs the detail, it can dispatch a scout at one ticket.
