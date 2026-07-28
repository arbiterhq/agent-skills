# Arbiter Agent Skills

Cross-platform agent skills by Posthuman Resources LLC (Mike Riley).

## Repository Layout

This repo is a Claude Code plugin marketplace, a Codex skill set, and a Gemini CLI extension simultaneously.

- `plugins/` contains the canonical skill sources, structured as Claude Code plugins
- `skills/` contains symlinks into `plugins/*/skills/*` for Codex and Gemini compatibility
- `.claude-plugin/marketplace.json` is the Claude Code marketplace manifest
- `gemini-extension.json` is the Gemini CLI extension manifest
- `package.json` at the root configures Bun workspaces (`plugins/*`); each plugin has its own `package.json` for workspace discovery

## Skills

- **agent-browser** (browser-buddy plugin): how to drive the agent-browser CLI; the plugin also ships the browser-buddy operator agent (haiku)
- **artistic-vision**: Gemini-powered vision, generation, and editing; Sharp-powered local processing
- **task-triage, worktree-pipeline, task-tracking** (night-shift plugin): unattended build runs; the plugin also ships an eight-agent roster and the /orchestrate, /drain, and /abort commands. Project specifics live in a `.claude/night-shift.md` adapter in the consuming repo, never in the package

## Conventions

- Never use em dashes or en dashes. Use commas, periods, colons, semicolons, or parentheses instead.
- Keep SKILL.md files under 500 lines. Put detailed content in references/ files.
- Scripts use #!/bin/bash with set -e. Status to stderr, machine output to stdout.
- All version bumps should update both marketplace.json and the relevant plugin.json.
- Use `bun` as the package manager. Do not run `npm install` or `pnpm install` at the root.
