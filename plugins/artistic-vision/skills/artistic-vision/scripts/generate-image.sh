#!/bin/bash
set -e

# Usage: generate-image.sh "prompt" [options]
# Wrapper around nano-banana with defaults

if [ -z "$1" ]; then
  echo "Usage: generate-image.sh \"prompt\" [nano-banana options]" >&2
  exit 1
fi

if ! command -v nano-banana &>/dev/null; then
  echo "Error: nano-banana is not installed. See setup.sh" >&2
  exit 1
fi

PROMPT="$1"
shift

echo "Generating image..." >&2
nano-banana "$PROMPT" "$@"
echo "Done." >&2
