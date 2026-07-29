# The project adapter

Everything project-specific lives in one file: `.claude/night-shift.md` in the repo the pipeline is driven from, meaning the one where the orchestrator command runs. That is usually the repo being built, but not always: a planning repo that wraps the built repo as a submodule drives the pipeline from outside it, and the adapter lives in the planning repo (Adaptig works this way; see `adaptig-example.md`). The file is named after the plugin that reads it, so a repo can carry adapters for several plugins without collision and it is obvious from the filename what consumes it.

The file has the same shape as a `SKILL.md`: YAML frontmatter plus a markdown body. The split is not cosmetic.

- **Frontmatter is configuration.** Skills read it as values. A missing or malformed required key is a hard stop at preflight, reported by name.
- **Body is instruction.** Agents read it as prose and weigh it. It is never parsed.

Keep configuration out of the body and judgment out of the frontmatter. The two halves fail differently: a wrong hook command should stop the run immediately, while a house rule about commit voice should shape a commit message and nothing else.

The test of whether the split is right: all three skills run against a repo that is not the one they were written for, with no edits to the package, only a new adapter file.

## Frontmatter keys

### Required

| Key | Type | Notes |
| --- | --- | --- |
| `repo` | string | Tracker identifier, for example `owner/name`. Without it there is no board to triage. |
| `base_branch` | string | Everything branches from it, everything merges to it. |
| `hooks.provision` | string | Command that creates a unit's environment. See the hook contract below. |
| `hooks.teardown` | string | Command that removes it. |
| `hooks.build` | string | Command that must pass before anything lands. |
| `hooks.integrate` | string | Command that squash-merges a branch onto the base branch. |

### Optional

| Key | Type | Default | Notes |
| --- | --- | --- | --- |
| `push_policy` | `after-each` \| `batched` \| `never` | `never` | Publishing is opt-in. |
| `concurrency_cap` | integer | `3` | Counts units, not processes. |
| `priority_order` | list | `[security, bug, feature]` | How the build queue is ordered. |
| `hooks.preflight` | string | none | Run once before the first dispatch. Non-zero exit stops the run. |
| `hooks.typecheck` | string | none | Compile hygiene, run inside a worktree. |
| `hooks.test` | string | none | Run by the verifier when defined. |
| `hooks.seed` | string | none | Resets a unit's data store to a known state. Must be idempotent. |
| `hooks.start` | string | none | Starts the dev server. Must honor the assigned port. |
| `overrides` | map | none | Per-role model and reasoning overrides. See below. |
| `references` | list of paths | none | Read-only prior art an agent may consult. |
| `prior_art` | boolean | `true` when `references` is set | Turns the planner's prior art mode on or off. |
| `design_reference` | path | none | What visual criteria are graded against. |
| `test_accounts` | list | none | Role plus how the credential is reached. See the line below. |

**Where the line on credentials falls.** Seed fixtures for a data store that is created and dropped per unit may be inline, password and all: they are fixtures for a throwaway database, usually already published in the project's own README, and a `password_ref` for them buys nothing but a secret-manager round trip in every worktree. Anything that authenticates against a shared or real system (staging, a tenant's data, a third-party API, anything that outlives the run) is a reference and never a value, no matter how convenient inlining it would be. If you cannot say which of the two an account is, it is the second one.

### Shape

```yaml
---
repo: owner/name
base_branch: main
push_policy: never
concurrency_cap: 3
priority_order: [security, bug, feature]

hooks:
  preflight: bash .claude/night-shift/preflight.sh
  provision: bash .claude/night-shift/wt.sh new
  teardown: bash .claude/night-shift/wt.sh remove
  integrate: bash .claude/night-shift/wt.sh integrate
  typecheck: bun x tsc -b
  build: bun run build
  test: bun test
  seed: bun run seed
  start: bun run start

overrides:
  scout: { model: sonnet }
  verifier: { model: sonnet, effort: medium }

references:
  - ../reference-app-one
  - ../reference-app-two
prior_art: true
design_reference: docs/09-design-system.md

test_accounts:
  - role: admin
    user: admin@example.com
    password_ref: op://Engineering/night-shift demo/password
  - role: member
    user: member@example.com
    password_ref: op://Engineering/night-shift demo/password
---
```

## The hook contract

Skills call hook names. They never contain a literal project command, and an agent that hardcodes one has broken the package.

Every hook runs from the repo root unless noted. Every hook reports failure with a non-zero exit and a one-line reason on stderr.

| Hook | Called with | Must do | Must print |
| --- | --- | --- | --- |
| `preflight` | nothing | Check every precondition the run needs: toolchain present, tracker authenticated, data store reachable, tree clean, stray environments swept | one line per problem found |
| `provision` | a slug | Create the worktree branched from the base branch, install or link dependencies, write the environment file, create and seed an isolated data store, allocate a unique port, and optionally start the server | `WORKTREE=<path>`, `PORT=<n>`, `SERVER=running\|not-started`, and any extra `KEY=VALUE` values agents will need, one per line |
| `teardown` | a slug | Remove the worktree, drop its data store, free the port | nothing required |
| `integrate` | a slug and a commit message | Squash-merge the branch onto the base branch as one commit | the new short SHA on success |
| `typecheck`, `build`, `test`, `seed` | nothing, run inside the worktree | What the name says | whatever the tool prints |
| `start` | nothing, with the assigned port in the environment | Start the app on that port | whatever the tool prints |

Two conventions the pipeline depends on:

- **`integrate` exit 3 means conflict.** Any other non-zero exit is a real failure. On exit 3 the integrator escalates to a fixer rather than resolving markers itself, so the hook should print the conflicting files and the exact commit message that must be used.
- **`provision` prints values, and agents receive them as values.** Nothing in the package hardcodes a path, a port, or a data store name.
- **Starting the server is optional, and `SERVER=` says what happened.** Start it if a running app at provision time is useful; leave it unstarted if the worktree is a copy of the base branch with nothing implemented yet, in which case the agent that builds the change starts it with the `start` hook on the assigned port and kills it when done. Either way, print the line: the pipeline passes it through to every dispatched agent, and an agent that is told the wrong thing wastes a round finding out.

If your `integrate` hook appends its own closing trailer (deriving the issue number from the branch name, for example), say so in the body. The integrator checks before writing one, and it never amends a commit to fix a trailer it could have passed correctly.

## Overrides

```yaml
overrides:
  scout: { model: sonnet }
  planner: { model: opus }
```

This map is read when the adapter is read, at the top of the run, and applies to every dispatch from then on, including the triage reading pass, which fires before this skill is ever loaded.

Both values resolve independently, first match wins:

1. an explicit model passed at dispatch (including flags to the foreground orchestrator command, `/orchestrate` by default and aliased in some repos)
2. this override map
3. the agent definition frontmatter
4. the class default for reasoning level (`fable` and `opus` high, `sonnet` medium; `haiku` has none)

One caveat worth knowing when writing this map: a model override applies at dispatch, but a reasoning override cannot (there is no dispatch-time effort parameter, and haiku takes no effort at all), so an `effort` set here only documents intent until it is edited into the agent definition or the session level. The full rules are in `models-and-effort.md` next to this file.

## The body

Everything an agent reads as instruction rather than configuration:

- house rules for generated content: voice, banned words, commit conventions, formatting
- what counts as production sensitive in this repo, which routes an issue to `HOLD`
- escalation policy: what to decide, what to ask about, and who to ask
- anything about the codebase an agent would otherwise have to infer: architectural contracts, where a new module goes, what "done" usually means here

Write it as prose an agent weighs, not as rules it parses. If something must be enforced exactly, it belongs in frontmatter or in a hook.
