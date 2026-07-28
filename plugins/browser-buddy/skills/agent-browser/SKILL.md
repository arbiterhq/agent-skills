---
name: agent-browser
description: >-
  Browser automation using the agent-browser CLI. Use when the user needs to
  interact with websites, navigate pages, fill forms, click buttons, take
  screenshots, scrape data, test web apps, do visual regression, or automate
  any browser-based task. Triggers include "open a website", "fill out a form",
  "scrape this page", "take a screenshot", "test this URL", "log in to a
  site", or "automate browser actions". For multi-step browser work, prefer
  launching the browser-buddy agent, which uses this skill internally.
---

# agent-browser

Drives a real Chrome instance via `agent-browser` (Vercel Labs' native Rust CLI, talking to Chrome over the Chrome DevTools Protocol). Instead of CSS selectors, it works from accessibility-tree snapshots whose elements are pre-labeled with refs like `@e3`; you snapshot, pick a ref, act, and re-snapshot.

## For the launching assistant: delegate multi-step work to the browser-buddy agent

**If you are the browser-buddy agent, this section is not for you: you are the operator, drive the CLI yourself and never launch another agent.**

Otherwise (you are the main assistant deciding how to do browser work): this plugin ships a `browser-buddy` agent (sonnet-powered) built for exactly this. Anything beyond one or two commands, navigating a site, filling forms across pages, reading screenshots and logs to judge whether things work, should be handed to it as a high-level brief ("test the whole checkout flow and report anything broken"). It does the browsing internally and returns a concise findings report, so bulky snapshots and screenshots never land in the parent context.

Drive the browser inline only for a quick one-shot (open a URL, grab one screenshot) or when the user is making the judgment call at each step and the conversation is the loop.

## Setup

Bun is the only external system dependency. The `agent-browser` binary is a workspace dependency of this plugin; Chrome for Testing is downloaded once.

```bash
# Once, from the agent-skills repo root:
./setup-browser-buddy.sh
```

That runs `bun install`, downloads Chrome, symlinks `agent-browser` into `~/.local/bin`, and runs a smoke test. In Claude Code the plugin's `bin/` directory is already on `PATH` when the plugin is enabled. If the command is missing, run the setup script, or call the shim directly at `plugins/browser-buddy/bin/agent-browser`. On Linux, if the browser fails to launch for missing system libraries, run `agent-browser install --with-deps` once.

## The core loop: snapshot then ref

```bash
agent-browser --session demo open https://example.com
agent-browser --session demo snapshot -i # -i = interactive elements only
# inspect the output, find @e3 = the search input
agent-browser --session demo fill @e3 "browser automation"
agent-browser --session demo click @e8               # submit
agent-browser --session demo wait --load networkidle # let the page settle
agent-browser --session demo snapshot -i             # previous refs are now stale
```

Refs are valid only against the snapshot they came from. Anything that mutates the DOM (navigation, clicks that open menus, async loads) invalidates them; stale refs return `Ref not found`. Re-snapshot after every meaningful interaction, and pair navigation with `wait --load networkidle` (or `wait --url <glob>`, `wait --text <string>`) so you don't race the page.

## Sessions

Every command runs against a browser session. Without `--session <name>` you get a default shared session, so unrelated tasks collide on cookies and tabs. **Always pass `--session <name>`.** Save and restore login state with `agent-browser state save state.json` / `state load state.json`. State files contain auth tokens: treat them as secrets, never commit them, delete them when the work is done.

## Full reference lives in the binary

The CLI ships its own version-matched documentation. Trust it over anything written here when they disagree.

```bash
agent-browser skills get core        # workflows, patterns, troubleshooting
agent-browser skills get core --full # + full command reference and templates
agent-browser skills list            # specialized guides: electron, slack, ...
```

## Hard-won gotchas

- **Modal, dropdown, and overlay content is invisible to `snapshot -i`.** Many frameworks render dialogs into a portal at the end of `<body>`. If `snapshot -i` shows the page as if your last click did nothing, drop the `-i` and run a full `snapshot`; the content is almost always there. Filter with `grep` if the output is large, or scope with `-s <selector>`.
- **`find` clicks by default.** `agent-browser find role button --name Submit` will _click_ Submit, not just locate it. Always pass an explicit action, and never use `find` to probe for existence; use `get count <selector>` or `is visible <selector>` instead.
- **`find text` is more forgiving than `find role --name`.** Composite accessible names (icons + text, nested spans) often fail exact-name matching. If `find role X --name Y` returns `Element not found`, try `find text "Y" click`.
- **Use `batch` for fixed sequences.** When the steps are known up front, one `batch` call runs them in a single process (measured roughly 2.7x faster than chaining `&&` for a four-step flow). Global flags like `--session` go before `batch`; `--bail` stops at the first failure.

  ```bash
  agent-browser --session demo batch --bail \
    "open https://example.com" \
    "wait --load networkidle" \
    "snapshot -i" \
    "get title"
  ```

  Chain separate calls with `&&` only when you must read a step's output before choosing the next action (the classic snapshot-then-ref case). The session daemon persists the browser between calls either way.

- **Screenshots default to PNG.** Pass `--screenshot-format jpeg` whenever the image will be read back by a model; JPEG costs a fraction of PNG in tokens. Keep PNG only for lossless needs (pixel diffing, transparency, icon work).
- **`--json` for machine-parseable output.** Works on read-style commands (`snapshot`, `get`, `is`, `cookies`, `network requests`); pair with `jq`.
- **Headless by default.** Pass `--headed` if the user wants to watch.
- **Timeouts.** If something needs longer than the default budget (slow page, large download), use an explicit `wait --load networkidle` or `wait --fn` rather than fighting the default.
- **Debugging.** `agent-browser console` and `agent-browser errors` surface the page's console log and uncaught exceptions; read them before concluding why a page misbehaves.

## When not to use this skill

If the task is a one-line `curl` or a static fetch, just use `curl`/`wget`. Reach for `agent-browser` when the page needs JavaScript execution, form interaction, login state, or visual capture.
