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

> Help text and error messages from the underlying CLI say `agent-browser`; that is the binary `bin/browser-buddy` wraps. Commands work identically through either name.

## Setup

Bun is the only external system dependency. The `agent-browser` binary is a workspace dependency of this plugin, and Chrome for Testing has to be downloaded once. The bootstrap script does all of it and puts `browser-buddy` on your `PATH`:

```bash
# Once, from the agent-skills repo root:
./setup-browser-buddy.sh
```

That runs `bun install` (vendors the binary), downloads Chrome, symlinks the wrapper into `~/.local/bin/browser-buddy`, warns if that directory is not on your `PATH`, and runs a smoke test. On Linux, if the browser fails to launch for missing system libraries, run `browser-buddy install --with-deps` once.

## Calling the wrapper

After setup, `browser-buddy` is a bare command that works from any directory:

```bash
browser-buddy --session demo open https://example.com
```

If it is **not** on your `PATH` (setup not run, or `~/.local/bin` not in `PATH`), the Skill loader prints `Base directory for this skill: <path>` when launching; call the wrapper relative to that base directory using one of:

```bash
# Option A: bind a shell variable to the absolute path.
BB="<base-dir>/bin/browser-buddy"
"$BB" --session demo open https://example.com

# Option B: cd into the skill once.
cd <base-dir>
bin/browser-buddy --session demo open https://example.com
```

Examples below use bare `browser-buddy`; substitute `"$BB"` or `bin/browser-buddy` if you are using a fallback. Confirm everything is wired up with a one-shot smoke test:

```bash
browser-buddy --session smoke open https://example.com && browser-buddy --session smoke snapshot -i && browser-buddy --session smoke close
```

## The one concept to internalize: snapshot then ref

You do not feed CSS selectors to `browser-buddy`. You first ask it for a **snapshot** of the page's accessibility tree, which returns elements pre-labeled with refs like `@e1`, `@e7`, `@e23`. Then you act on those refs.

```bash
browser-buddy --session demo open https://example.com
browser-buddy --session demo snapshot -i           # -i = interactive elements only
# inspect the output, find @e3 = the search input
browser-buddy --session demo fill @e3 "browser automation"
browser-buddy --session demo click @e8             # submit
browser-buddy --session demo wait --load networkidle  # let the page settle before re-snapshotting
browser-buddy --session demo snapshot -i           # refs from the previous snapshot are now stale
browser-buddy --session demo click @e12            # @e12 = a result link in the new tree
```

Refs are valid only against the snapshot they came from. Anything that mutates the DOM (navigation, clicks that open menus, async content loads) invalidates them. Re-snapshot after every meaningful interaction. Stale refs return `Ref not found`.

**Modal, dropdown, and overlay content is the #1 reason snapshots come up empty.** Many JS frameworks render dialogs into a portal at the end of `<body>` outside the main interactive region. If `snapshot -i` shows the page as if your last click did nothing, drop the `-i` and run `snapshot` (full tree). The new content is almost always there. Filter with `grep` if the output is large.

When you need raw control, fall back to `find` (semantic locators by role/text/label/testid) or `eval` (arbitrary JavaScript). Prefer refs first; they keep token usage low.

### Using `find` safely

Two things to know before reaching for `find`:

- **Default action is `click`.** `browser-buddy find role button --name Submit` will *click* Submit, not just locate it. Always pass an explicit action, and never use `find` to probe for existence. For existence checks use `browser-buddy get count <selector>` or `browser-buddy is visible <selector>`.
- **`find text` is more forgiving than `find role --name`.** Composite accessible names (icons + text, nested spans, screen-reader-only prefixes) often fail exact-name matching even when the element is plainly in the snapshot. If `find role X --name Y` returns `Element not found`, try `find text "Y" click`.

## Chaining: one bash call, many steps

You usually want the browser to take several steps from a single shell command. There are two ways, and picking the right one matters.

**`batch` (default for fixed sequences).** When you know the steps up front, put them in one `batch` call. It runs every step in a single process, skipping the per-command startup that chained `&&` pays each time (measured roughly 2.7x faster for a four-step flow). Each step is a quoted argument; global flags like `--session` go before `batch`.

```bash
browser-buddy --session demo batch --bail \
  "open https://example.com" \
  "wait --load networkidle" \
  "snapshot -i" \
  "get title" \
  "close"
```

`--bail` stops at the first failing step; without it, `batch` runs every step and reports failures at the end.

**Chained `&&` (when you must read output between steps).** `batch` can't feed back a value discovered mid-run, so when the next action depends on reading the previous output, chain separate calls with `&&`. The classic case is the snapshot-then-ref loop: you snapshot, read the tree to pick `@e8`, then act.

```bash
browser-buddy --session demo open https://example.com && browser-buddy --session demo snapshot -i
# read the snapshot, choose a ref, then:
browser-buddy --session demo fill @e3 "query" && browser-buddy --session demo click @e8
```

The browser persists between calls via the session daemon, so state carries across both patterns as long as you pass the same `--session`.

**Screenshots inside `batch`.** The wrapper's automatic PNG-to-JPG conversion only fires when `screenshot` is the top-level command. Inside `batch` it is bypassed, so a `.jpg` path would receive raw PNG bytes. To get JPEG from a `batch` step, use the CLI's own encoder with the global flag: `browser-buddy --screenshot-format jpeg --session demo batch ... "screenshot --full out.jpg" ...`.

## Sessions in one paragraph

Every command runs against a browser session. Without `--session <name>` you get a default shared session, so two unrelated tasks will collide on cookies and tabs. **Always pass `--session <name>`.** Save and restore login state with `browser-buddy state save state.json` and `browser-buddy state load state.json`. Treat state files as secrets; never commit them. Full detail in `references/sessions.md`.

## Output for agents

Append `--json` to any read-style command (`snapshot`, `get`, `is`, `cookies`, `network requests`) to get machine-parseable output. Pair with `jq` when scripting.

```bash
browser-buddy --session demo snapshot -i --json | jq '.elements[] | select(.role=="button")'
```

## What lives where

- `references/commands.md`: full command surface (batch, navigation, interaction, get, find, wait, network, tabs, frames, dialogs, mouse, settings, eval, state, auth vault, config file, debug, record)
- `references/snapshot-refs.md`: deeper dive on the snapshot/ref model and how to keep refs fresh
- `references/sessions.md`: sessions, state save/load, persistent profiles, credential handling
- `references/recording.md`: screenshots, full-page captures, PDF export, video recording
- `templates/navigate-and-screenshot.sh`: minimal capture flow
- `templates/form-fill.sh`: snapshot, fill, submit, verify
- `templates/batch-flow.sh`: one `batch` call driving a fixed multi-step sequence
- `templates/authenticated-flow.sh`: log in once, save state, reuse on later runs
- `browser-buddy skills get core --full`: the upstream CLI ships its own version-matched docs (overview, full command reference, copy-paste templates). When `references/commands.md` and the upstream output disagree, trust the upstream. For specialized topics, run `browser-buddy skills list` and then `browser-buddy skills get <name>` (covers `electron`, `slack`, exploratory testing, cloud providers, etc.).

## Common gotchas

- **Stale refs after navigation.** Always re-snapshot after `click`, form submission, route changes, or anything that loads content. Pair the click with `wait --load networkidle` (or `wait --url <glob>`, `wait --text <string>`) before the next snapshot, otherwise you race the page.
- **Modal/portal content is invisible to `snapshot -i`.** Drop the `-i` after opening any dialog, dropdown, autocomplete, or command palette.
- **`find` clicks by default.** Always pass an explicit action; use `get count` / `is visible` for existence checks.
- **Headless by default.** Pass `--headed` if the user wants to watch.
- **Default session is sticky.** Always pass `--session <name>` so unrelated tasks don't share cookies and tabs.
- **State files contain auth tokens.** Add to `.gitignore`. Delete after use if the work is short-lived.
- **Timeouts.** Operations have a built-in budget below the CLI's IPC timeout. If something needs longer (slow page, large download), use explicit `wait --load networkidle` or `wait --fn` rather than fighting the default.
- **Screenshot format.** The wrapper post-processes screenshots to JPG by default, since JPG is far cheaper than PNG in LLM tokens when the image is fed back to an agent. Use `browser-buddy screenshot ./out.jpg` and you get a real JPEG. To keep PNG output (for lossless regression diffing, transparency, or icon work), either use a `.png` file extension or pass the wrapper-only `--png` flag. This conversion does **not** apply to `screenshot` steps inside `batch`; use the global `--screenshot-format jpeg` flag there instead.
- **Use `batch` for fixed multi-step flows.** When the steps are known up front, one `batch` call is faster and cleaner than chaining `&&` (it avoids per-command startup). Reach for `&&` only when you must read a step's output before choosing the next action. See "Chaining: one bash call, many steps."
- **Element not snapshotted.** `snapshot -i` filters to interactive elements. If you can't find what you need, re-run without `-i`, or scope with `-s <selector>`.

## When not to use this skill

If the task is a one-line `curl` or a static fetch, just use `curl`/`wget`. Reach for `browser-buddy` when the page needs JavaScript execution, form interaction, login state, or visual capture.
