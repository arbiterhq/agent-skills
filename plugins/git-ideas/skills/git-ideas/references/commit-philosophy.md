# The One Idea Per Commit Philosophy

<!-- TODO: Flesh out into a full essay -->

## Core Principle

Every commit should represent exactly one logical change. The atomic unit is the *idea*, not the file, not the line.

## Why This Matters

- **Reviewability**: Small, focused commits are easier to review.
- **Bisectability**: `git bisect` works best when each commit is a single logical step.
- **Revertability**: If a change causes problems, you can revert exactly one idea without collateral damage.
- **History as documentation**: A clean commit history tells the story of how the codebase evolved and, more importantly, why.

## How to Tell If a Commit Is Atomic

- Can you describe it without using "and"?
- Would reverting it remove exactly one logical change?
- Does every changed file serve the same purpose?

## When to Split

- "Add user model and fix navbar" is two commits.
- "Refactor auth and add tests" is two commits.
- "Add migration, model, and API endpoint for users" might be one commit if they form a single coherent feature, or three commits if each can stand alone.

## The Commit Message

The subject line says what changed. The body says why. The diff shows how.

If you cannot write a clear one-line subject, the commit is probably too large.
