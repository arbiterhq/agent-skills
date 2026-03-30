# Arbiter Agent Skills

Cross-platform agent skills by Posthuman Resources LLC (Mike Riley).

## Repository Layout

This repo is a Claude Code plugin marketplace, a Codex skill set, and a Gemini CLI extension simultaneously.

- `plugins/` contains the canonical skill sources, structured as Claude Code plugins
- `skills/` contains symlinks into `plugins/*/skills/*` for Codex and Gemini compatibility
- `.claude-plugin/marketplace.json` is the Claude Code marketplace manifest
- `gemini-extension.json` is the Gemini CLI extension manifest

## Skills

- **browser-buddy**: Browser automation via agent-browser CLI
- **artistic-vision**: Image generation (Nano Banana) and processing (Sharp/ImageMagick)
- **git-ideas**: Git workflows, worktrees, atomic commits, stacking

## Conventions

- Never use em dashes or en dashes. Use commas, periods, colons, semicolons, or parentheses instead.
- Keep SKILL.md files under 500 lines. Put detailed content in references/ files.
- Scripts use #!/bin/bash with set -e. Status to stderr, machine output to stdout.
- All version bumps should update both marketplace.json and the relevant plugin.json.
