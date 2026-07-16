# browser-buddy

Browser automation plugin built on Vercel Labs' [agent-browser](https://github.com/vercel-labs/agent-browser) CLI. It ships two pieces:

- **`agent-browser` skill**: teaches an agent how to drive the CLI directly (snapshot-ref workflow, sessions, gotchas). The CLI's own `agent-browser skills get core --full` is the canonical, version-matched command reference; the skill stays thin on purpose.
- **`browser-buddy` agent**: a haiku-powered operator subagent. Give it a high-level task ("browse the whole site, use all the forms, report anything broken") and it does the multi-step browsing, screenshot reading, and console-log diagnosis internally, returning a concise findings report. All the opinionated workflow (JPEG screenshots, session hygiene, evidence-based reporting) lives here.

## Setup

Bun is the only external system dependency. The `agent-browser` binary is vendored through Bun workspaces.

```bash
# Once, from the agent-skills repo root:
./setup-browser-buddy.sh
```

That runs `bun install`, downloads Chrome for Testing (skipped if a compatible Chrome, Brave, Playwright, or Puppeteer install exists), and symlinks `agent-browser` into `~/.local/bin`. In Claude Code the plugin's `bin/` directory is on `PATH` automatically while the plugin is enabled.

## What's in this plugin

- `skills/agent-browser/SKILL.md`: entry point for agents; the core loop, sessions, and hard-won gotchas, deferring to `agent-browser skills get core --full` for the full reference.
- `agents/browser-buddy.md`: the operator agent definition (`model: haiku`, preloads the skill).
- `bin/agent-browser`: bash shim that resolves the vendored binary.

Note: upstream distributes its own `agent-browser` skill stub. If you install both this plugin and upstream's, the skill names overlap; keep one.

## Credit

The `agent-browser` CLI is built and maintained by Vercel Labs. This plugin wraps it with our own prose, workflow opinions, and the browser-buddy operator agent.
