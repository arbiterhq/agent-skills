# Change Stacking Guide

<!-- TODO: Flesh out with diagrams and detailed workflows -->

## What Is Stacking?

Stacking is a workflow where you create a chain of dependent branches, each building on the previous. Instead of one large PR, you produce a series of small, reviewable PRs.

## The Stack Structure

```
main
  -> feature/base        (PR #1: targets main)
    -> feature/part-1    (PR #2: targets feature/base)
      -> feature/part-2  (PR #3: targets feature/part-1)
```

## Benefits

- Reviewers see small, focused diffs
- Each PR can be merged independently (bottom-up)
- Parallel review: multiple PRs can be reviewed simultaneously
- Clear dependency chain

## Updating the Stack

When you need to change a branch in the middle:

1. Make changes on the target branch
2. Rebase each branch above it, in order
3. Force-push with `--force-with-lease`

## Merging the Stack

Merge bottom-up:

1. Merge the base PR into main
2. Retarget the next PR to main
3. Rebase if needed
4. Merge
5. Repeat

## Common Pitfalls

- Forgetting to rebase the whole stack after changes
- Using `--force` instead of `--force-with-lease`
- Creating stacks that are too deep (3-4 levels is usually the practical limit)
- Not communicating the stack structure to reviewers
