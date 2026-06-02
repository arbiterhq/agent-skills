#!/bin/bash
# One bash call, several browser steps: drive a fixed sequence with `batch`.
# `batch` runs every step in a single process, so it skips the per-command bun
# + sharp startup that chained `&&` pays on each invocation (measured ~2.7x
# faster for a 4-step flow). Use it whenever the steps are known up front and
# you don't need to read a snapshot to pick the next ref.
#
# When you DO need to branch on output (snapshot -> choose @ref -> act), fall
# back to chained `&&` of separate calls; see form-fill.sh.
#
# Usage: ./batch-flow.sh <url> [output.jpg]

set -e

URL="${1:?usage: $0 <url> [output.jpg]}"
OUT="${2:-./batch-shot.jpg}"
SESSION="${AGENT_BROWSER_SESSION:-buddy-batch}"

HERE="$(cd "$(dirname "$0")" && pwd)"
BB="$HERE/../bin/browser-buddy"

# Screenshot note: the wrapper's automatic PNG->JPG conversion only applies when
# `screenshot` is the top-level command. Inside `batch` it is bypassed, so a
# `.jpg` path would otherwise receive PNG bytes. Use the CLI's own JPEG encoder
# via the global --screenshot-format jpeg flag (placed before `batch`).
#
# --bail stops at the first failing step instead of running the rest.
"$BB" --session "$SESSION" --screenshot-format jpeg batch --bail \
  "open $URL" \
  "wait --load networkidle" \
  "snapshot -i" \
  "screenshot --full $OUT" \
  "close"

echo "$OUT"
