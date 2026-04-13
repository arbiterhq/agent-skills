#!/bin/bash
# Snapshot a page, fill a form via semantic locators, submit, and confirm.
# This template uses `find` (semantic locators) rather than refs, because the
# targets are stable enough that we don't need a snapshot round-trip. For
# ref-based flows, see the snapshot example at the bottom.
#
# Usage: ./form-fill.sh <url> <email> <password>

set -e

URL="${1:?usage: $0 <url> <email> <password>}"
EMAIL="${2:?usage: $0 <url> <email> <password>}"
PASSWORD="${3:?usage: $0 <url> <email> <password>}"
SESSION="${AGENT_BROWSER_SESSION:-buddy-form}"

HERE="$(cd "$(dirname "$0")" && pwd)"
BB="$HERE/../bin/browser-buddy"

echo "opening $URL" >&2
"$BB" --session "$SESSION" open "$URL" >/dev/null
"$BB" --session "$SESSION" wait --load networkidle >/dev/null

echo "filling email and password" >&2
"$BB" --session "$SESSION" find label "Email" fill "$EMAIL" >/dev/null
"$BB" --session "$SESSION" find label "Password" fill "$PASSWORD" >/dev/null

echo "submitting" >&2
"$BB" --session "$SESSION" find role button click --name "Sign in" >/dev/null

echo "waiting for post-login state" >&2
"$BB" --session "$SESSION" wait --load networkidle >/dev/null

CURRENT_URL="$("$BB" --session "$SESSION" get url)"
echo "landed at: $CURRENT_URL" >&2
echo "$CURRENT_URL"

# --- Ref-based alternative (uncomment if `find` locators don't match) ---
# "$BB" --session "$SESSION" snapshot -i
# # inspect output, identify refs for the email input, password input, submit button
# "$BB" --session "$SESSION" fill @e3 "$EMAIL"
# "$BB" --session "$SESSION" fill @e4 "$PASSWORD"
# "$BB" --session "$SESSION" click @e5
