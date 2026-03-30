#!/bin/bash
set -e

# Create a worktree with naming conventions
# Usage: create-worktree.sh <feature-name> [base-branch]

if [ -z "$1" ]; then
  echo "Usage: create-worktree.sh <feature-name> [base-branch]" >&2
  echo "Creates a worktree at ../<project>-<feature-name>" >&2
  exit 1
fi

FEATURE="$1"
BASE="${2:-HEAD}"
PROJECT=$(basename "$(git rev-parse --show-toplevel)")
WORKTREE_PATH="../${PROJECT}-${FEATURE}"
BRANCH="feature/${FEATURE}"

if [ -d "$WORKTREE_PATH" ]; then
  echo "Error: Directory already exists: $WORKTREE_PATH" >&2
  exit 1
fi

echo "Creating worktree:" >&2
echo "  Path: $WORKTREE_PATH" >&2
echo "  Branch: $BRANCH" >&2
echo "  Base: $BASE" >&2

git worktree add -b "$BRANCH" "$WORKTREE_PATH" "$BASE"

echo "" >&2
echo "Worktree created. Switch to it with:" >&2
echo "  cd $WORKTREE_PATH" >&2
