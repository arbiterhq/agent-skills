# Arbiter Agent Skills

Cross-platform agent skills for [Claude Code](https://claude.com/claude-code), [Codex CLI](https://github.com/openai/codex), and [Gemini CLI](https://github.com/google-gemini/gemini-cli). By [Posthuman Resources LLC](https://posthuman.help).

## Skills

### Browser Buddy

Browser automation built on Vercel's [agent-browser](https://github.com/vercel-labs/agent-browser) CLI. Ships an `agent-browser` skill (how to drive the CLI: snapshot refs, sessions, gotchas) and a `browser-buddy` agent, a haiku-powered operator that takes a high-level task like "browse the whole site, use all the forms, report anything broken" and returns a concise findings report.

### Artistic Vision

Image generation via [Nano Banana](https://github.com/kingbootoshi/nano-banana-2-skill) (Google Gemini image models) and local image processing via Sharp, ImageMagick, and FFmpeg. Generate from prompts, edit existing images, create transparent assets, resize, convert, and batch process.

### Night Shift

Runs a board of work unattended. Ships a roster of small composable agents (orchestrator, delegate, planner, researcher, scout, verifier, fixer, integrator), three skills (`task-triage`, `worktree-pipeline`, `task-tracking`), and the `/orchestrate`, `/drain`, and `/abort` commands. `/orchestrate any open bugs on github` triages the board, builds each unit in its own worktree, grades it against criteria it did not write for itself, and lands it, while you steer from the foreground. Every agent is usable on its own. Nothing in the package names a project: all specifics live in a `.claude/night-shift.md` adapter in the consuming repo.

## Installation

### Claude Code

```
/plugin marketplace add arbiterhq/agent-skills
```

Then install individual plugins:

```
/plugin install browser-buddy@arbiterhq
/plugin install artistic-vision@arbiterhq
/plugin install night-shift@arbiterhq
```

### Codex CLI

Using the built-in skill installer:

```
$skill-installer install browser-buddy from arbiterhq/agent-skills
```

Or manually:

```bash
git clone https://github.com/arbiterhq/agent-skills.git
cd agent-skills && bash install.sh
```

### Gemini CLI

```
gemini extensions install https://github.com/arbiterhq/agent-skills
```

### Universal (npx)

Works with Claude Code, Codex, Gemini CLI, Cursor, and 40+ other agents:

```
npx skills add arbiterhq/agent-skills
```

## Development

This repo is a [Bun](https://bun.com) workspace. To get started:

```bash
bun install
```

Each plugin under `plugins/*` is a workspace member. The root package is private and not published to npm; distribution happens via the Git repo itself (see Installation above).

## Repository Structure

```
agent-skills/
  package.json                      # Bun workspace root (private)
  .claude-plugin/marketplace.json   # Claude Code marketplace manifest
  gemini-extension.json             # Gemini CLI extension manifest
  plugins/                          # Canonical skill sources (Claude Code plugins)
    browser-buddy/
      package.json                  # Workspace member
      .claude-plugin/plugin.json    # Claude Code plugin manifest
      skills/agent-browser/SKILL.md
      agents/browser-buddy.md       # Operator subagent (Claude Code only)
    artistic-vision/
    night-shift/
      agents/                       # Agent roster (Claude Code only)
      commands/                     # /orchestrate, /drain, /abort (Claude Code only)
      skills/                       # task-triage, worktree-pipeline, task-tracking
  skills/                           # Symlinks for Codex and Gemini discovery
  CLAUDE.md                         # Claude Code project context
  AGENTS.md                         # Codex project context
  GEMINI.md                         # Gemini CLI project context
```

Skills live in `plugins/<name>/skills/<name>/SKILL.md` with the canonical source of truth. The `skills/` directory at the root contains symlinks for cross-tool compatibility.

## Contributing

1. Fork the repo
2. Create a feature branch
3. Follow the conventions in CLAUDE.md (no em dashes, SKILL.md under 500 lines, scripts use set -e)
4. Submit a PR

To add a new skill:

1. Create a new directory under `plugins/<skill-name>/`
2. Add the `.claude-plugin/plugin.json` manifest
3. Create `skills/<skill-name>/SKILL.md` with YAML frontmatter
4. Add a symlink in the root `skills/` directory
5. Add an entry to `.claude-plugin/marketplace.json`

## License

[MIT](LICENSE) - Posthuman Resources LLC
