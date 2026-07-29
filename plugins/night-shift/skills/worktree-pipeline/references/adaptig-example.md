# Example adapter: Adaptig

A filled-in `.claude/night-shift.md`, mirrored from the repo the package was decomposed from. Copy it, replace every value, and delete what does not apply.

It lives in the outer **planning** repo (`is4co/adaptig`), which is where the pipeline is driven from; the repo being built (`is4co/adaptig-incubation`) is that repo's `platform/` submodule. This is the wrapped-submodule layout the adapter spec describes: the adapter sits where the orchestrator runs, and the built repo carries its own ground-rules file (`platform/AGENTS.md`) that every dispatched agent reads at the worktree root. The hook scripts live at `.claude/grind/*.sh` in the planning repo and target `platform/` from outside it; they keep the `grind` name because that repo's run command is `/grind`.

Note the inline demo passwords: they are seed fixtures for a per-worktree throwaway database, already published in the built repo's README, which is exactly the case the adapter spec's credential rule allows to be a value. Anything that outlives the run would be a `password_ref` instead. The prose keeps Adaptig's own house punctuation (em dashes), because an adapter is written in the consuming repo's voice, not this package's.

---

```markdown
---
repo: is4co/adaptig-incubation
base_branch: main
push_policy: after-each
concurrency_cap: 3
priority_order: [security, bug, feature]

hooks:
  preflight: bash .claude/grind/preflight.sh
  provision: bash .claude/grind/wt.sh new
  teardown: bash .claude/grind/wt.sh remove
  integrate: bash .claude/grind/wt.sh integrate
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
  - ${ADAPTIG_ROOT}/docs/_sweep
prior_art: true
design_reference: ${ADAPTIG_ROOT}/docs/09-design-system.md

test_accounts:
  - role: platform-staff
    user: staff@adaptig.ai
    password: adaptig!
  - role: educator
    user: educator@adaptig.ai
    password: adaptig!
  - role: org-admin
    user: admin@mattel.com
    password: adaptig!
  - role: student-graduated
    user: student@mattel.com
    password: adaptig!
  - role: student-ungraduated
    user: student@globex.com
    password: adaptig!
  - role: student-partway
    user: student2@globex.com
    password: adaptig!
---

## Two repos, and which one the pipeline runs in

This adapter lives in the outer **planning** repo (`is4co/adaptig`), which is where
the pipeline is driven from, not in the repo being built. Everything the pipeline
builds happens in the **platform** submodule at `platform/`
(`is4co/adaptig-incubation`): every branch, every commit, every push. The outer repo
is planning docs and the proposal, and the only change that legitimately lands in it
is an edit to this harness itself, and only when the user asks.

Never push any `adaptig/*` upstream. Run every tracker command against
`is4co/adaptig-incubation`.

## Hook behavior worth knowing

`preflight` reports and **exits 0 even on warnings**, on purpose, so the orchestrator
reads the report and decides. Read the `WARN` lines and fix or accept each one before
dispatching.

`provision` does **not** start the server, and reports `SERVER=not-started`. The
verifier builds and starts the app itself on the assigned `PORT` using the `start`
hook, and kills it when done — by PID, never by name. `provision` also writes `PORT`,
`APP_URL`, and `DATABASE_URL` into each worktree's `.env`, so a lane is isolated even
if an agent forgets to pass them.

`integrate` exits 3 on conflict and prints the conflicting files plus the exact
commit message to use. It derives `Closes #<n>` from the branch name and appends it
when the message carries no closing keyword, so pass an ordinary conventional subject
and let the hook add the trailer. Never amend a commit to fix a trailer.

`teardown` refuses while a worktree is dirty or still in use by a live process
(exit 4). That refusal is a signal that an agent is still working in there.

## Toolchain

Bun only. Never npm or yarn. `start` is single-process and serves the SPA and the
API on one port; never use the two-process dev server in a worktree, its proxy
points at a hardcoded port and parallel lanes would collide on it.

## Data

Postgres only. Schema is idempotent SQL applied at boot; the `seed` hook loads demo
fixtures and is safe to re-run. Each worktree gets its own throwaway database,
created and seeded by `provision` and dropped by `teardown`. A lane that cannot
reach its database has an environment problem to report, never evidence that the
feature under test is broken.

The demo passwords above are local seed fixtures for a throwaway database, not
credentials. They are already published in `platform/README.md`.

## Prior art

The platform consolidates existing apps whose product decisions are already made.
Before building, and before asking a product question, read the reference
implementation and take its current behavior as the baseline. `${ADAPTIG_ROOT}` is
this repo's absolute path — the orchestrator resolves it once at the start of the
run and passes it to agents as a value; never hardcode it.

Every reference feature is in scope: the reference apps are the parity floor, not a
menu. Diverging from baseline is recorded as `INTENTIONAL_DIVERGENCE`; a gap the
reference does not cover is recorded as `NO_REFERENCE_FOUND`. Both surface in the
return, because divergence from the reference is the user's call to make, not a
subagent's to settle quietly. The only prohibitions are copying reference code and
connecting to reference databases. Clean-room has never meant do not look.

## Ground rules live in the built repo

The platform's own `AGENTS.md` is the authoritative ground-rules file; every
dispatched agent reads it at the worktree root before implementing. One rule worth
repeating because the verifier acts on it: any UI change is graded in **both light
and dark themes**.

The platform is production-bound software, pre-production today: no live data, no
downstream consumer, so replace legacy shapes outright rather than preserving them
behind compatibility shims, while never breaking a feature the app relies on.

## Voice and generated content

Narrative, anti-hype, concrete. Specific numbers where they exist. No emojis. Em
dashes are the house punctuation. Banned: leverage, innovative, cutting-edge,
empower, unlock, democratize, disruption, thought leader, game-changer, deep dive.

Commits are conventional and always reference their issue.

## Production sensitive

Route to `HOLD`, write a runbook, and wait for explicit approval: data migrations,
DNS changes, anything touching real user data, and anything hard to reverse.

Hosting is Render with autodeploy on a `main` push, so **a push is a deploy**.
Pushing after each clean integration is the standing, pre-authorized flow for this
repo, which is why `push_policy` is `after-each`. Never push mid-conflict, push only
clean built state, and stop pushing and surface it if a deploy breaks.

## Escalation

Decide it yourself when prior art or the code answers it, which is most of the time.
Ask when guessing risks meaningful rework, a wrong product decision, an irreversible
action, or a data-integrity mistake. Ask once, on the ticket, with a recommendation
attached, and mark the comment as automated.
```

---

## What moved out of the old command

Everything above used to live in the `grind` command alongside the roles and the procedures. Nothing in the package names Adaptig, bun, Render, Postgres, a port, or a demo account any more. The pipeline calls `provision` and `build`; the adapter decides what those mean.

Two Adaptig specifics that became package concepts rather than adapter values:

- The outer planning repo path (`ADAPTIG_ROOT`) is now just an entry in `references`, resolved once at run start and passed to agents as a value at dispatch. No agent hardcodes it.
- The reference-first policy is now the planner's prior art mode, switched on by `prior_art` and pointed at by `references`.
