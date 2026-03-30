#!/bin/bash
set -e

# Visualize and manage stacked branches
# Usage: stack-changes.sh [rebase]

CURRENT=$(git branch --show-current)

echo "Current branch: $CURRENT" >&2
echo "" >&2
echo "Branch stack (recent branches with upstream tracking):" >&2
echo "======================================================" >&2

# Show branches that look like they might be part of a stack
git branch -vv --sort=-committerdate | head -20

echo "" >&2
echo "Worktrees:" >&2
echo "==========" >&2
git worktree list

if [ "$1" = "rebase" ]; then
  echo "" >&2
  echo "To rebase the stack, run these commands in order (bottom-up):" >&2
  echo "  git checkout <branch>" >&2
  echo "  git rebase <parent-branch>" >&2
  echo "  git push --force-with-lease" >&2
  echo "" >&2
  echo "Repeat for each branch in the stack." >&2
fi
