# Example adapter: Adaptig

A filled-in `.claude/night-shift.md`, written for the repo the package was decomposed from. Copy it, replace every value, and delete what does not apply.

It lives in the repo where the building happens (the platform repo), not in the outer planning repo. The planning repo appears here only as a read-only reference path.

---

```markdown
---
repo: is4co/adaptig-incubation
base_branch: main
push_policy: after-each
concurrency_cap: 3
priority_order: [security, bug, feature]

hooks:
  preflight: bash .claude/night-shift/preflight.sh
  provision: bash .claude/night-shift/wt.sh new
  teardown: bash .claude/night-shift/wt.sh remove
  integrate: bash .claude/night-shift/wt.sh integrate
  typecheck: bun x tsc -b
  build: bun run build
  seed: bun run seed
  start: bun run start

overrides:
  scout: { model: sonnet }

references:
  - ${ADAPTIG_ROOT}/shift-pioneer-path-755f19b7
  - ${ADAPTIG_ROOT}/shapecoach-v1
  - ${ADAPTIG_ROOT}/docs/05-product-truth.md
prior_art: true
design_reference: ${ADAPTIG_ROOT}/docs/09-design-system.md

test_accounts:
  - role: platform-staff
    user: staff@adaptig.ai
    password_ref: op://Engineering/adaptig demo accounts/password
  - role: educator
    user: educator@adaptig.ai
    password_ref: op://Engineering/adaptig demo accounts/password
  - role: org-admin
    user: admin@mattel.com
    password_ref: op://Engineering/adaptig demo accounts/password
  - role: student
    user: student@mattel.com
    password_ref: op://Engineering/adaptig demo accounts/password
---

## Toolchain

Bun only. Never npm or yarn. Dev normally runs as two processes (web and api on
separate ports), but a pipeline worktree always uses the single-process `start`
hook on its assigned port: the two-process dev server proxies to a hardcoded
port and parallel worktrees would collide on it.

## Data

Postgres. Schema is idempotent SQL applied at boot; the `seed` hook loads demo
fixtures and is safe to re-run. Each worktree gets its own throwaway database,
created and seeded by `provision` and dropped by `teardown`, so heavy data
mutation in one lane cannot affect another. A worktree that genuinely cannot
reach its database has an environment problem, not a broken feature.

## Voice and generated content

Narrative, anti-hype. No emojis. Em dashes are the house punctuation here, which
is the opposite of the agent-skills repo convention; follow this repo when
writing in this repo. Banned words: leverage, innovative, empower, unlock,
cutting-edge, game-changer.

Commits are conventional and always reference their issue: `Closes #<n>` when
the change resolves it, `Refs #<n>` when it only advances it. The `integrate`
hook derives `Closes #<n>` from the branch name and appends it when the message
carries no closing keyword, so pass an ordinary conventional subject and let it
add the trailer. Never amend a commit to fix a trailer.

## Architectural contracts

Server logic goes through `defineAction` only, with an auth level and zod
schemas in and out. A new app follows the two-file contract
(`registerCollection` plus `registerApp` plus `defineAction`, then `defineApp`);
`src/apps/prompt-library/` is the reference. Roles are admin, educator, student,
plus a platform-staff flag, all under one login.

## Prior art

The platform consolidates existing apps whose product decisions are already
made. Before building, or before asking a product question, read the reference
implementation and take its current behavior as the baseline. Diverging is
legitimate as a deliberate consolidation choice and is recorded as
`INTENTIONAL_DIVERGENCE`; a gap the reference does not cover is recorded as
`NO_REFERENCE_FOUND`. The only prohibitions are copying reference code and
connecting to reference databases. Reading them is expected.

## Production sensitive

Route to HOLD, write a runbook, and wait for explicit approval: data migrations,
DNS changes, anything touching real user data, and anything hard to reverse.
Hosting is Render with autodeploy on a `main` push, so a push is a deploy: never
push mid-conflict, and stop pushing if a deploy breaks.

## Escalation

Decide it yourself when prior art or the code answers it. Ask when guessing
risks meaningful rework, a wrong product decision, an irreversible action, or a
data-integrity mistake. Ask once, on the ticket, with a recommendation attached.
```

---

## What moved out of the old command

Everything above used to live in the `grind` command alongside the roles and the procedures. Nothing in the package names Adaptig, bun, Render, Postgres, a port, or a demo account any more. The pipeline calls `provision` and `build`; the adapter decides what those mean.

Two Adaptig specifics that became package concepts rather than adapter values:

- The outer planning repo path (`ADAPTIG_ROOT`) is now just an entry in `references`, passed to agents as a value at dispatch. No agent hardcodes it.
- The reference-first policy is now the planner's prior art mode, switched on by `prior_art` and pointed at by `references`.
