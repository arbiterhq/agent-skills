# browser-buddy

Browser automation skill built on top of Vercel Labs' [agent-browser](https://github.com/vercel-labs/agent-browser) CLI. Use it to drive a real Chrome instance for navigation, form filling, scraping, screenshotting, video recording, and end-to-end web testing.

## Setup

Bun is the only external system dependency. The `agent-browser` binary is vendored through Bun workspaces.

```bash
# Once, from the agent-skills repo root:
bun install

# Once, to download Chrome for Testing (skipped automatically if you already
# have a compatible Chrome, Brave, Playwright, or Puppeteer install):
plugins/browser-buddy/skills/browser-buddy/bin/browser-buddy install
```

After that, invoke commands through `bin/browser-buddy` (the wrapper resolves the vendored binary automatically).

## What's in this skill

- `skills/browser-buddy/SKILL.md` — entry point for agents; explains the snapshot-ref pattern and common gotchas.
- `skills/browser-buddy/bin/browser-buddy` — bash wrapper that resolves the vendored `agent-browser` binary.
- `skills/browser-buddy/references/` — deeper dives on commands, snapshot-refs, sessions, and recording.
- `skills/browser-buddy/templates/` — copy-paste starting points for navigation + screenshot, form fill, and authenticated session reuse.

## Credit

The `agent-browser` CLI is built and maintained by Vercel Labs. This skill wraps it with our own prose and examples.
