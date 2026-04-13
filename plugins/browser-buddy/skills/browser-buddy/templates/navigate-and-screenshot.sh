#!/bin/bash
# Navigate to a URL and capture a full-page screenshot.
# Defaults to JPG; PNGs tokenize heavily when fed back to an agent, so only
# override the extension when lossless output is actually needed.
# Usage: ./navigate-and-screenshot.sh <url> [output.jpg]

set -e

URL="${1:?usage: $0 <url> [output.jpg]}"
OUT="${2:-./screenshot.jpg}"
SESSION="${AGENT_BROWSER_SESSION:-buddy-shot}"

HERE="$(cd "$(dirname "$0")" && pwd)"
BB="$HERE/../bin/browser-buddy"

echo "navigating to $URL (session: $SESSION)" >&2
"$BB" --session "$SESSION" open "$URL" >/dev/null

echo "waiting for network idle" >&2
"$BB" --session "$SESSION" wait --load networkidle >/dev/null

echo "capturing full-page screenshot to $OUT" >&2
"$BB" --session "$SESSION" screenshot --full "$OUT" >/dev/null

echo "$OUT"
