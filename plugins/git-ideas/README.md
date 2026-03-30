# Git Ideas

Intelligent git workflow management built around the "one idea per commit" philosophy. Covers atomic commits, worktrees for parallel development, change stacking, and GitHub PR workflows.

## What It Does

- Guide commits toward atomic, single-idea changes with conventional message formatting
- Manage git worktrees for parallel development without branch switching
- Stack changes across dependent branches for incremental PR review
- GitHub PR creation and review workflows
- Merge strategy selection (merge, squash, rebase)

## Usage

This skill is activated automatically when you ask an agent to commit, create worktrees, make PRs, stack changes, or clean up git history.

## Structure

```
skills/git-ideas/
  SKILL.md              # Core skill instructions and methodology
  references/           # Worktree patterns, commit philosophy, stacking guide
  scripts/              # Helper scripts for commits, worktrees, and stacking
```
