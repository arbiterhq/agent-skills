---
name: git-ideas
description: >-
  Intelligent git workflow management. Use when the user wants to commit
  changes (following atomic one-idea-per-commit methodology), manage git
  worktrees for parallel development, create or manage GitHub PRs, stack
  changes across dependent branches, organize git history, handle merge
  strategies, or improve their git workflow. Triggers include "commit",
  "create a worktree", "make a PR", "stack these changes", "clean up
  my commits", "split this commit", or "set up parallel work".
---

# Git Ideas

An opinionated git workflow system built around one core principle: **one idea per commit**. This skill encodes a methodology for atomic commits, worktree-based parallel development, change stacking, and GitHub PR workflows.

## The One Idea Per Commit Philosophy

Every commit should represent exactly one logical change. Not one file, not one line, one *idea*.

If you find yourself writing "and" in a commit message, the commit probably needs to be split. "Add user model and fix navbar styling" is two ideas. "Add user model" is one.

The commit message explains **why** the change was made, not what changed. The diff shows what. The message provides the context that the diff cannot.

See `references/commit-philosophy.md` for the full essay on this methodology.

## Commit Message Format

```
<type>(<scope>): <description>

<body explaining why this change was made>
```

### Types

| Type | Purpose |
|---|---|
| `feat` | A new feature or capability |
| `fix` | A bug fix |
| `refactor` | Code restructuring without behavior change |
| `docs` | Documentation only |
| `test` | Adding or updating tests |
| `chore` | Build, CI, tooling, dependencies |
| `style` | Formatting, whitespace, semicolons |
| `perf` | Performance improvement |

### Rules

- First line under 72 characters
- Use imperative mood: "add", "fix", "remove" (not "added", "fixes", "removed")
- Scope is optional but useful for larger repos: `feat(auth):`, `fix(api):`
- Body is separated from the subject by a blank line
- Body explains the motivation, not the mechanics

### Examples

Good:
```
feat(auth): add OAuth2 PKCE flow for mobile clients

The implicit grant flow is deprecated by OAuth 2.1. Mobile clients
need PKCE for secure token exchange without a client secret.
```

```
fix: prevent duplicate webhook deliveries on retry

The idempotency check was comparing timestamps with second precision,
but retries can happen within the same second. Switch to request IDs.
```

Bad:
```
update code
fix stuff
WIP
addressed review comments
```

## Worktree Management

Git worktrees let you check out multiple branches simultaneously in separate directories. Use them for parallel development instead of stashing or switching branches.

### Create a worktree

```bash
# Convention: sibling directory named <project>-<feature>
git worktree add ../myproject-new-auth feature/new-auth

# If the branch doesn't exist yet, create it from current HEAD
git worktree add -b feature/new-auth ../myproject-new-auth
```

### List active worktrees

```bash
git worktree list
```

### Remove a worktree

```bash
# After merging or when done
git worktree remove ../myproject-new-auth
```

### When to use worktrees

- You need to review a PR while your current branch has uncommitted work
- You want to run tests on one branch while developing on another
- You are working on two features that touch different parts of the codebase
- You need to reproduce a bug on main without losing your current context

### Worktree hygiene

- Always give worktrees descriptive names
- Remove worktrees after their branch is merged
- Run `git worktree prune` periodically to clean stale entries
- Each worktree has its own working tree but shares the same `.git` objects

See `references/worktree-patterns.md` for advanced patterns including CI worktrees and review workflows.

## Change Stacking

Stacked PRs break a large feature into a chain of small, reviewable PRs where each builds on the previous.

### The pattern

```
main
  -> feature/base        (shared foundation)
    -> feature/part-1    (first logical chunk)
      -> feature/part-2  (builds on part-1)
```

Each PR targets the branch below it, not main (except the bottom of the stack).

### Creating a stack

```bash
# Start from main
git checkout main && git pull

# Create the base
git checkout -b feature/base
# ... make foundational changes, commit ...

# Stack part 1 on top
git checkout -b feature/part-1
# ... make changes that build on base, commit ...

# Stack part 2 on top of part 1
git checkout -b feature/part-2
# ... make changes that build on part-1, commit ...
```

### Creating PRs for a stack

```bash
# Bottom of stack targets main
gh pr create --base main --head feature/base --title "feat: base infrastructure"

# Each subsequent PR targets the branch below
gh pr create --base feature/base --head feature/part-1 --title "feat: part 1"
gh pr create --base feature/part-1 --head feature/part-2 --title "feat: part 2"
```

### Updating a stack after review feedback

When you need to change a branch in the middle of the stack:

```bash
# Fix something in feature/base
git checkout feature/base
# ... make changes, commit ...
git push

# Rebase each branch on top
git checkout feature/part-1
git rebase feature/base
git push --force-with-lease

git checkout feature/part-2
git rebase feature/part-1
git push --force-with-lease
```

Always use `--force-with-lease` (not `--force`) when pushing rebased stacked branches. It prevents overwriting changes someone else may have pushed.

### Merging a stack

Merge from the bottom up. After merging `feature/base` into main:

1. Update the next PR's base to `main`
2. Rebase if needed
3. Merge
4. Repeat

See `references/stacking-guide.md` for the complete stacking methodology with diagrams.

## GitHub PR Workflows

### Creating a PR

```bash
# Basic
gh pr create --title "feat: add user profiles" --body "Adds the user profile page and API endpoints."

# Draft PR (work in progress)
gh pr create --draft --title "wip: new search backend"

# Link to an issue
gh pr create --title "fix: resolve timeout errors" --body "Fixes #42"
```

### PR conventions

- Keep the title under 70 characters
- Use the same type prefixes as commits: feat, fix, refactor, etc.
- Body should explain what the PR achieves and why, plus a test plan
- Link related issues with "Fixes #N" or "Closes #N" in the body
- Use draft PRs for work you want early feedback on

### Review workflow

```bash
# Check out a PR locally
gh pr checkout 123

# View PR diff
gh pr diff 123

# Approve
gh pr review 123 --approve

# Request changes
gh pr review 123 --request-changes --body "See inline comments"
```

## Merge Strategies

### When to use each strategy

| Strategy | When to use | Command |
|---|---|---|
| Merge commit | Default for most PRs. Preserves full history. | `gh pr merge --merge` |
| Squash | PR has messy WIP commits. Produces one clean commit. | `gh pr merge --squash` |
| Rebase | PR has clean atomic commits you want to preserve linearly. | `gh pr merge --rebase` |

### Interactive rebase for cleanup

Before submitting a PR, clean up your commits:

```bash
# Rebase last 5 commits interactively
git rebase -i HEAD~5
```

In the editor:
- `pick` to keep a commit as-is
- `squash` (or `s`) to merge into the previous commit
- `reword` (or `r`) to change the commit message
- `edit` (or `e`) to stop and amend the commit
- `drop` (or `d`) to remove a commit entirely

### Handling merge conflicts in stacks

When rebasing a stack and hitting conflicts:

1. Resolve the conflict in the current file
2. `git add` the resolved files
3. `git rebase --continue`
4. After the rebase completes, continue rebasing the branches above

## Scripts

Helper scripts are available in the `scripts/` directory:

- `scripts/atomic-commit.sh`: Interactive commit helper. Shows the staged diff, asks for type and scope, validates the message follows conventions, and creates the commit.
- `scripts/create-worktree.sh`: Creates a worktree with the naming convention `../<project>-<feature>`, handling branch creation.
- `scripts/stack-changes.sh`: Visualizes the current stack and helps rebase all branches in order.

Run them from the skill's scripts directory or copy to your PATH.

## Quick Reference

| Task | Command |
|---|---|
| Atomic commit | `git add -p && git commit` (stage hunks selectively) |
| New worktree | `git worktree add -b feature/x ../project-x` |
| List worktrees | `git worktree list` |
| Create PR | `gh pr create --title "type: description"` |
| Draft PR | `gh pr create --draft` |
| Stack a branch | `git checkout -b feature/next` (from current feature branch) |
| Rebase stack | `git rebase <parent-branch>` on each branch, bottom-up |
| Clean history | `git rebase -i HEAD~N` |
| Safe force push | `git push --force-with-lease` |
