#!/bin/bash
# Reuse a saved authenticated session. Logs in once and persists state to disk;
# subsequent runs skip the login step.
#
# Usage:
#   ./authenticated-flow.sh login <login-url> <email> <password> <state-file>
#   ./authenticated-flow.sh use   <target-url> <state-file>

set -e

MODE="${1:?usage: $0 <login|use> ...}"
SESSION="${AGENT_BROWSER_SESSION:-buddy-auth}"

HERE="$(cd "$(dirname "$0")" && pwd)"
BB="$HERE/../bin/browser-buddy"

case "$MODE" in
  login)
    LOGIN_URL="${2:?usage: $0 login <login-url> <email> <password> <state-file>}"
    EMAIL="${3:?missing email}"
    PASSWORD="${4:?missing password}"
    STATE_FILE="${5:?missing state-file path}"

    echo "logging in at $LOGIN_URL (session: $SESSION)" >&2
    "$BB" --session "$SESSION" open "$LOGIN_URL" >/dev/null
    "$BB" --session "$SESSION" wait --load networkidle >/dev/null

    "$BB" --session "$SESSION" find label "Email" fill "$EMAIL" >/dev/null
    "$BB" --session "$SESSION" find label "Password" fill "$PASSWORD" >/dev/null
    "$BB" --session "$SESSION" find role button click --name "Sign in" >/dev/null

    "$BB" --session "$SESSION" wait --load networkidle >/dev/null

    echo "saving session state to $STATE_FILE" >&2
    "$BB" --session "$SESSION" state save "$STATE_FILE" >/dev/null

    echo "$STATE_FILE"
    ;;

  use)
    TARGET_URL="${2:?usage: $0 use <target-url> <state-file>}"
    STATE_FILE="${3:?missing state-file path}"

    if [[ ! -f "$STATE_FILE" ]]; then
      echo "state file not found: $STATE_FILE (run \`$0 login ...\` first)" >&2
      exit 1
    fi

    echo "loading state from $STATE_FILE (session: $SESSION)" >&2
    "$BB" --session "$SESSION" state load "$STATE_FILE" >/dev/null

    echo "navigating to $TARGET_URL" >&2
    "$BB" --session "$SESSION" open "$TARGET_URL" >/dev/null
    "$BB" --session "$SESSION" wait --load networkidle >/dev/null

    "$BB" --session "$SESSION" get url
    ;;

  *)
    echo "unknown mode: $MODE (use 'login' or 'use')" >&2
    exit 2
    ;;
esac
