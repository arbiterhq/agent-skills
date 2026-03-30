# Worktree Patterns

<!-- TODO: Flesh out with advanced patterns -->

## Basic Worktree Workflow

Create, use, and clean up worktrees for parallel development.

## Review Worktree

Check out a PR in a dedicated worktree for review without disrupting your current work.

```bash
git worktree add ../project-review-pr123 pr-branch
cd ../project-review-pr123
# Review, test, etc.
git worktree remove ../project-review-pr123
```

## CI Worktree

Use a worktree to run tests on a different branch in the background.

## Worktree with Stacked Branches

Managing worktrees when working with stacked PRs.

## Cleanup Recipes

```bash
# Remove all worktrees for merged branches
git worktree list | grep -v "main\|master" | awk '{print $1}' | while read wt; do
  echo "Consider removing: $wt"
done

# Prune stale worktree references
git worktree prune
```
