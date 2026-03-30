#!/bin/bash
set -e

echo "Arbiter Agent Skills Installer" >&2
echo "================================" >&2

# Detect which tools are available
CLAUDE_CODE=false
CODEX=false
GEMINI=false

if command -v claude &>/dev/null; then CLAUDE_CODE=true; fi
if command -v codex &>/dev/null; then CODEX=true; fi
if command -v gemini &>/dev/null; then GEMINI=true; fi

REPO_URL="https://github.com/arbiterhq/agent-skills"

if $CLAUDE_CODE; then
  echo "Installing for Claude Code..." >&2
  echo "Run: /plugin marketplace add arbiterhq/agent-skills" >&2
fi

if $CODEX; then
  echo "Installing skills for Codex CLI..." >&2
  mkdir -p ~/.codex/skills
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  for skill in "$SCRIPT_DIR"/skills/*/; do
    skill_name=$(basename "$skill")
    if [ -L "$skill" ]; then
      # Resolve symlink and copy
      real_path=$(readlink -f "$skill")
      cp -r "$real_path" ~/.codex/skills/"$skill_name"
    else
      cp -r "$skill" ~/.codex/skills/"$skill_name"
    fi
    echo "  Installed: $skill_name" >&2
  done
  echo "Restart Codex to pick up new skills." >&2
fi

if $GEMINI; then
  echo "Installing for Gemini CLI..." >&2
  echo "Run: gemini extensions install $REPO_URL" >&2
fi

if ! $CLAUDE_CODE && ! $CODEX && ! $GEMINI; then
  echo "No supported agent tools detected (claude, codex, gemini)." >&2
  echo "You can also use: npx skills add arbiterhq/agent-skills" >&2
fi
