#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="$HOME/.claude/agents"

echo "Linking agents from $SCRIPT_DIR into $TARGET_DIR" >&2
mkdir -p "$TARGET_DIR"

for agent_file in "$SCRIPT_DIR"/plugins/*/agents/*.md; do
  [ -f "$agent_file" ] || continue
  name=$(basename "$agent_file")
  target="$TARGET_DIR/$name"

  if [ -e "$target" ] && [ ! -L "$target" ]; then
    echo "  skip $name: $target exists as a real file, not a symlink" >&2
    continue
  fi

  if [ -L "$target" ] && [ "$(readlink "$target")" = "$agent_file" ]; then
    echo "  ok   $name (already linked)" >&2
    continue
  fi

  ln -sfn "$agent_file" "$target"
  echo "  link $name -> $agent_file" >&2
done

echo "Done. Restart any running Claude Code sessions to pick up new or changed agents." >&2
