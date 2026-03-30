#!/bin/bash
set -e

# Interactive commit helper that guides toward single-idea commits
# Usage: atomic-commit.sh

echo "Atomic Commit Helper" >&2
echo "=====================" >&2

# Show what's staged
STAGED=$(git diff --cached --stat)
if [ -z "$STAGED" ]; then
  echo "Nothing staged. Use 'git add -p' to stage changes selectively." >&2
  exit 1
fi

echo "" >&2
echo "Staged changes:" >&2
echo "$STAGED" >&2
echo "" >&2

# Prompt for type
echo "Commit type (feat/fix/refactor/docs/test/chore/style/perf):" >&2
read -r TYPE

# Prompt for optional scope
echo "Scope (optional, press Enter to skip):" >&2
read -r SCOPE

# Prompt for description
echo "Description (imperative mood, under 72 chars):" >&2
read -r DESC

# Prompt for body
echo "Why was this change made? (optional, press Enter to skip):" >&2
read -r BODY

# Build the message
if [ -n "$SCOPE" ]; then
  SUBJECT="${TYPE}(${SCOPE}): ${DESC}"
else
  SUBJECT="${TYPE}: ${DESC}"
fi

# Check length
if [ ${#SUBJECT} -gt 72 ]; then
  echo "Warning: subject line is ${#SUBJECT} characters (max 72)." >&2
fi

# Check for "and" (potential split signal)
if echo "$DESC" | grep -qi "\band\b"; then
  echo "Warning: description contains 'and'. Consider splitting into multiple commits." >&2
fi

# Build full message
if [ -n "$BODY" ]; then
  MESSAGE="${SUBJECT}

${BODY}"
else
  MESSAGE="$SUBJECT"
fi

echo "" >&2
echo "Commit message:" >&2
echo "$MESSAGE" >&2
echo "" >&2
echo "Proceed? (y/n)" >&2
read -r CONFIRM

if [ "$CONFIRM" = "y" ] || [ "$CONFIRM" = "Y" ]; then
  git commit -m "$MESSAGE"
  echo "Committed." >&2
else
  echo "Aborted." >&2
fi
