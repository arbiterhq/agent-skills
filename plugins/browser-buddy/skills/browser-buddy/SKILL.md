---
name: browser-buddy
description: >-
  Browser automation using the agent-browser CLI. Use when the user needs to
  interact with websites, navigate pages, fill forms, click buttons, take
  screenshots, scrape data, test web apps, do visual regression, or automate
  any browser-based task. Triggers include "open a website", "fill out a form",
  "scrape this page", "take a screenshot", "test this URL", "log in to a
  site", or "automate browser actions".
---

# browser-buddy

Drives a real Chrome instance via the vendored `agent-browser` CLI (a native Rust binary that talks to Chrome over the Chrome DevTools Protocol). Use it whenever the user wants something done in a browser, including navigation, clicking, typing, scraping, screenshotting, video recording, or testing a web app.

## Setup

Bun is the only external system dependency. The `agent-browser` binary is a workspace dependency of this plugin.

```bash
# Once, from the agent-skills repo root:
bun install

# Once, to download Chrome for Testing (skipped automatically if you already
# have a compatible Chrome, Brave, Playwright, or Puppeteer install):
bin/browser-buddy install
```

All commands in this skill are invoked through `bin/browser-buddy` rather than a globally-installed binary. The wrapper resolves the vendored `agent-browser` binary by walking up to the nearest `node_modules/.bin/agent-browser`.

## The one concept to internalize: snapshot then ref

You do not feed CSS selectors to `browser-buddy`. You first ask it for a **snapshot** of the page's accessibility tree, which returns elements pre-labeled with refs like `@e1`, `@e7`, `@e23`. Then you act on those refs.

```bash
bin/browser-buddy open https://example.com
bin/browser-buddy snapshot -i              # -i = interactive elements only
# inspect the output, find @e3 = the search input
bin/browser-buddy fill @e3 "browser automation"
bin/browser-buddy snapshot -i              # re-snapshot: the page changed
bin/browser-buddy click @e8                # @e8 = the submit button in the new tree
```

Refs are valid only against the snapshot they came from. Anything that mutates the DOM (navigation, clicks that open menus, async content loads) invalidates them. Re-snapshot after every meaningful interaction. Stale refs return `Ref not found`.

When you need raw control, fall back to `find` (semantic locators by role/text/label/testid) or `eval` (arbitrary JavaScript). Prefer refs first; they keep token usage low.

## Sessions in one paragraph

Every command runs against a browser session. Without `--session <name>` you get a default shared session. Pass `--session work` or `--session scrape-target` to isolate cookies, storage, and tabs. Save and restore login state with `bin/browser-buddy state save state.json` and `bin/browser-buddy state load state.json`. Treat state files as secrets; never commit them. Full detail in `references/sessions.md`.

## Output for agents

Append `--json` to any read-style command (`snapshot`, `get`, `is`, `cookies`, `network requests`) to get machine-parseable output. Pair with `jq` when scripting.

```bash
bin/browser-buddy snapshot -i --json | jq '.elements[] | select(.role=="button")'
```

## What lives where

- `references/commands.md` — the full command surface (navigation, interaction, get, find, wait, network, tabs, frames, dialogs, mouse, settings, eval, state, debug)
- `references/snapshot-refs.md` — deeper dive on the snapshot/ref model and how to keep refs fresh
- `references/sessions.md` — sessions, state save/load, persistent profiles, credential handling
- `references/recording.md` — screenshots, full-page captures, PDF export, video recording
- `templates/navigate-and-screenshot.sh` — minimal capture flow
- `templates/form-fill.sh` — snapshot, fill, submit, verify
- `templates/authenticated-flow.sh` — log in once, save state, reuse on later runs

## Common gotchas

- **Stale refs after navigation.** Always re-snapshot after `click`, form submission, route changes, or anything that loads content.
- **Headless by default.** Pass `--headed` if the user wants to watch.
- **Default session is sticky.** Two unrelated tasks both running without `--session` will share cookies and tabs. Name the session when isolation matters.
- **State files contain auth tokens.** Add to `.gitignore`. Delete after use if the work is short-lived.
- **Timeouts.** Operations have a built-in budget below the CLI's IPC timeout. If something needs longer (slow page, large download), use explicit `wait --load networkidle` or `wait --fn` rather than fighting the default.
- **Screenshot format.** The wrapper post-processes screenshots to JPG by default, since JPG is far cheaper than PNG in LLM tokens when the image is fed back to an agent. Use `bin/browser-buddy screenshot ./out.jpg` and you get a real JPEG. To keep PNG output (for lossless regression diffing, transparency, or icon work), either use a `.png` file extension or pass the wrapper-only `--png` flag.
- **Element not snapshotted.** `snapshot -i` filters to interactive elements. If you can't find what you need, re-run without `-i`, or scope with `-s <selector>`.

## When not to use this skill

If the task is a one-line `curl` or a static fetch, just use `curl`/`wget`. Reach for `browser-buddy` when the page needs JavaScript execution, form interaction, login state, or visual capture.
