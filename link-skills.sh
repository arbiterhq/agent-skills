#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="$HOME/.claude/skills"

echo "Linking skills from $SCRIPT_DIR into $TARGET_DIR" >&2
mkdir -p "$TARGET_DIR"

for skill_dir in "$SCRIPT_DIR"/plugins/*/skills/*/; do
  [ -d "$skill_dir" ] || continue
  name=$(basename "$skill_dir")
  target="$TARGET_DIR/$name"
  source="${skill_dir%/}"

  if [ -e "$target" ] && [ ! -L "$target" ]; then
    echo "  skip $name: $target exists as a real directory, not a symlink" >&2
    continue
  fi

  if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
    echo "  ok   $name (already linked)" >&2
    continue
  fi

  ln -sfn "$source" "$target"
  echo "  link $name -> $source" >&2
done

echo "Done. Restart any running Claude Code sessions to pick up new or changed skills." >&2
