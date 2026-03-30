# Arbiter Agent Skills

Cross-platform agent skills by Posthuman Resources LLC.

## Repository Layout

This repo distributes agent skills for Claude Code, Codex CLI, and Gemini CLI.

- Skills follow the open Agent Skills specification (SKILL.md with YAML frontmatter)
- Canonical sources are in `plugins/*/skills/*/`
- Flat symlinks in `skills/` for Codex and Gemini discovery

## Skills

- **browser-buddy**: Browser automation via agent-browser CLI
- **artistic-vision**: Image generation (Nano Banana) and processing (Sharp/ImageMagick)
- **git-ideas**: Git workflows, worktrees, atomic commits, stacking

## Working Agreements

- Keep SKILL.md files under 500 lines
- Use progressive disclosure: reference files for detailed docs
- Scripts should be bash with set -e, status to stderr, output to stdout
- Never use em dashes or en dashes in any written content
