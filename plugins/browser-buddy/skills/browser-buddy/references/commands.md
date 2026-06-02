# Command reference

Working reference for the `agent-browser` CLI surface as exposed through the `browser-buddy` wrapper. Command names and flags are the upstream CLI's own; the explanations and examples are ours. The canonical, version-matched listing ships with the binary itself, surfaced via:

```bash
browser-buddy skills get core --full
```

When something here disagrees with that output, trust the binary.

All read-style commands accept `--json` for `jq`-friendly output.

## Batch (one call, many steps)

Run a fixed sequence of steps in a single process. This skips the per-command startup that chained `&&` pays on every invocation (roughly 2.7x faster for a four-step flow), so it is the default whenever the steps are known up front. Each step is a quoted string; global flags go before `batch`.

```bash
browser-buddy --session demo batch --bail \
  "open https://example.com" \
  "wait --load networkidle" \
  "snapshot -i" \
  "get title" \
  "close"
```

| Flag | Effect |
|---|---|
| `--bail` | Stop at the first failing step. Without it, every step runs and failures are reported at the end. |

Steps can be passed as quoted arguments (above) or piped on stdin as JSON (a JSON array of token arrays; run `browser-buddy batch --help` for the exact shape). Add `--json` to get results back as a JSON array. `batch` cannot feed a value discovered mid-run into a later step, so when the next action depends on reading the previous output (snapshot, pick a ref, act), chain separate calls with `&&` instead. Note the wrapper's PNG-to-JPG screenshot conversion does not apply inside `batch`; pass the global `--screenshot-format jpeg` flag for JPEG output there.

## Navigation

| Command | Notes |
|---|---|
| `open <url>` | Primary navigation. Aliases: `goto`, `navigate`. Accepts `https://`, `http://`, `file://`, `about:`, `data:`. Bare hosts get `https://` prepended. |
| `back` / `forward` / `reload` | History controls. |
| `close` | Close the session's browser. Aliases: `quit`, `exit`. |
| `connect <port>` | Attach to a running Chrome via CDP. |

```bash
browser-buddy open https://news.ycombinator.com
browser-buddy reload
```

## Snapshot

The heart of the workflow. Returns a labeled tree of page elements.

| Flag | Effect |
|---|---|
| `-i` | Interactive elements only (shorter, usually what you want). |
| `-c` | Compact output. |
| `-d <n>` | Limit tree depth. |
| `-s <selector>` | Scope to a CSS selector. |

```bash
browser-buddy snapshot -i
browser-buddy snapshot -s "main" -d 3
```

Iframes one level deep are inlined automatically. Re-snapshot after anything that mutates the DOM.

## Interaction (ref-based)

All of these take an `@ref` from the most recent snapshot.

| Command | Purpose |
|---|---|
| `click <@ref>` | Click. Add `--new-tab` to open links in a new tab. |
| `dblclick <@ref>` | Double click. |
| `focus <@ref>` | Move focus without clicking. |
| `fill <@ref> <text>` | Overwrite an input's value. |
| `type <@ref> <text>` | Type keystrokes (fires keydown/keypress/keyup). |
| `hover <@ref>` | Trigger hover state. |
| `check <@ref>` / `uncheck <@ref>` | Checkboxes and radios. |
| `select <@ref> <value>` | `<select>` elements; multiple values allowed. |
| `scrollintoview <@ref>` | Alias `scrollinto`. |
| `drag <@ref> <@ref>` | Source to target. |
| `upload <@ref> <filepath>` | Set a file input. |

Prefer `fill` over `type` for plain form inputs; `type` is for when you actually need key-by-key events (autocomplete dropdowns, custom editors).

## Keyboard and mouse (ref-less)

| Command | Purpose |
|---|---|
| `press <key>` | Chords allowed: `press Control+a`, `press Shift+Tab`. Alias `key`. |
| `keydown <key>` / `keyup <key>` | Hold modifiers across multiple actions. |
| `scroll <direction> [pixels]` | Defaults: `down 300`. |
| `mouse move <x> <y>` | Absolute viewport coords. |
| `mouse down <button>` / `mouse up <button>` | For dragging or long presses. |
| `mouse wheel <delta>` | Programmatic wheel. |

For inputs that swallow synthetic key events:

```bash
browser-buddy focus @e1
browser-buddy keyboard inserttext "raw text"   # bypasses key events
browser-buddy keyboard type "real keystrokes"
```

## Semantic locators (no snapshot needed)

`find` performs a locate-then-act in a single call. Useful when you know what you're looking for by role, label, or testid.

```bash
browser-buddy find role button click --name "Submit"
browser-buddy find text "Sign in" click
browser-buddy find text "Sign in" click --exact
browser-buddy find label "Email" fill "me@example.com"
browser-buddy find testid header-nav hover
browser-buddy find placeholder "Search" type "agent-browser"
```

Variants: `find role`, `find text`, `find label`, `find placeholder`, `find alt`, `find title`, `find testid`, `find first <selector>`, `find last <selector>`, `find nth <n> <selector>`.

## Reading state

| Command | Returns |
|---|---|
| `get text <@ref>` | Inner text. |
| `get html <@ref>` | Outer HTML. |
| `get value <@ref>` | Input value. |
| `get attr <@ref> <name>` | A single attribute. |
| `get title` / `get url` / `get cdp-url` | Page-level. |
| `get count <selector>` | Matching element count. |
| `get box <@ref>` | Bounding box. |
| `get styles <@ref>` | Computed styles. |
| `is visible <@ref>` / `is enabled <@ref>` / `is checked <@ref>` | Boolean checks. |

## Waiting

Pick the flavor that matches what you're actually waiting for.

```bash
browser-buddy wait @e5                        # element presence
browser-buddy wait 500                        # milliseconds
browser-buddy wait --text "Dashboard"         # text appears
browser-buddy wait --url "**/home"            # URL matches glob
browser-buddy wait --load networkidle         # load state
browser-buddy wait --fn "document.readyState === 'complete'"
```

Short aliases: `-t`, `-u`, `-l`, `-f`. Default operation timeout is 25s.

## Screenshots and PDF

```bash
browser-buddy screenshot ./out.jpg            # real JPEG (post-processed via sharp)
browser-buddy screenshot --full ./out.jpg     # whole page, JPEG
browser-buddy screenshot ./out.png            # PNG (extension keeps it lossless)
browser-buddy screenshot --png ./out.jpg      # also PNG (--png is the explicit opt-out)
browser-buddy screenshot --annotate ./map.jpg # numbered overlays keyed to snapshot refs
browser-buddy pdf ./page.pdf
```

The underlying CLI always emits PNG. Our wrapper post-processes to JPG by default because PNG tokenizes much more heavily when the image is handed to an LLM. Trigger PNG output by either using a `.png` extension or passing the wrapper-only `--png` flag (it is stripped before the underlying CLI sees it). Use PNG when you need lossless pixels: regression diffing, transparency, icon work.

Omit the path and the wrapper passes through to the underlying CLI, which writes a temp PNG and prints the location. See `recording.md` for video.

## Video recording

```bash
browser-buddy record start ./demo.webm
# ... run your automation ...
browser-buddy record stop
browser-buddy record restart ./take2.webm    # stop current, start fresh
```

Default container is WebM (VP8/VP9). Recording is session-scoped; if you want one continuous capture across commands, pass the same `--session` to all of them.

## JavaScript

```bash
browser-buddy eval "document.title"                            # simple expressions
browser-buddy eval -b ZG9jdW1lbnQudGl0bGU=                     # base64 (avoids shell quoting)
echo "Array.from(document.links).map(a=>a.href)" | browser-buddy eval --stdin
```

`eval` returns a serialized result. For complex DOM inspection, prefer `--stdin` with a heredoc or `-b` with base64. Inline `eval "..."` works only for simple expressions.

## Network

```bash
browser-buddy network route "**/api/**" --body '{"stub": true}'   # mock responses
browser-buddy network route "**/ads/**" --abort                   # block URLs
browser-buddy network unroute "**/api/**"
browser-buddy network requests --filter graphql
```

## Cookies and storage

```bash
browser-buddy cookies                         # list all
browser-buddy cookies set session abc123
browser-buddy cookies clear

browser-buddy storage local                   # list all localStorage
browser-buddy storage local theme             # one key
browser-buddy storage local set theme dark
browser-buddy storage local clear
browser-buddy storage session ...             # same shape, sessionStorage
```

## Tabs, windows, frames, dialogs

Tab IDs are stable strings (`t1`, `t2`, `t3`) and are never reused within a session. **Bare integers are rejected** — use `t1`, not `1`. User-assigned labels work anywhere a tab ref is accepted.

```bash
browser-buddy tab                             # list tabs
browser-buddy tab new https://example.com
browser-buddy tab new --label docs https://docs.example.com
browser-buddy tab t2                          # switch to tab by id
browser-buddy tab docs                        # switch to tab by label
browser-buddy tab close                       # close current
browser-buddy tab close t2                    # by id
browser-buddy tab close docs                  # by label
browser-buddy window new

browser-buddy frame "iframe[name=checkout]"   # enter iframe (CSS selector)
browser-buddy frame @e3                       # or by element ref
browser-buddy frame main                      # exit back to main doc

browser-buddy dialog accept "optional text"   # confirm/prompt
browser-buddy dialog dismiss
browser-buddy dialog status
```

By default, `alert` and `beforeunload` auto-accept. Pass `--no-auto-dialog` if you need to inspect them first.

## Browser settings

```bash
browser-buddy set viewport 1280 800
browser-buddy set viewport 1280 800 2         # with DPR
browser-buddy set device "iPhone 14"
browser-buddy set geo 37.7749 -122.4194
browser-buddy set offline on
browser-buddy set headers '{"X-Test":"1"}'
browser-buddy set credentials user pass       # HTTP Basic
browser-buddy set media dark
browser-buddy set media light reduced-motion
```

## State (sessions, auth, persistence)

State files capture cookies + localStorage + sessionStorage so you can restore a logged-in session later.

```bash
browser-buddy state save ./state.json            # save current state to a file
browser-buddy state load ./state.json            # restore it into the session
browser-buddy state list                         # list saved state files
browser-buddy state show ./state.json            # summarize a state file
browser-buddy state rename old new               # rename a saved state
browser-buddy state clear [session-name] [--all] # delete saved states
browser-buddy state clean --older-than 30        # delete states older than N days
```

Covered in depth in `sessions.md`, including `--session-name` (auto-save/restore), `--state` (load on launch), and `--profile` (persistent Chrome profile). State files contain auth tokens: keep them out of git, and set `AGENT_BROWSER_ENCRYPTION_KEY` (64-char hex) to encrypt them at rest.

## Auth vault

Distinct from raw state files: the auth vault stores named credential profiles and replays them into login forms. Use it when you log in to the same site repeatedly.

```bash
browser-buddy auth save github --url https://github.com/login --username me
browser-buddy auth login github                  # navigate + fill the saved form
browser-buddy auth list                          # list saved profiles
browser-buddy auth show github                   # show profile metadata (no secrets)
browser-buddy auth delete github
```

Pass the password via `--password-stdin` (read from stdin) rather than `--password` so it does not land in shell history. See `sessions.md` for the full credential-handling guidance.

## Debugging

```bash
browser-buddy console                         # page console log
browser-buddy errors                          # uncaught errors
browser-buddy highlight @e5                   # flash element on screen
browser-buddy inspect                         # open DevTools
browser-buddy trace start
browser-buddy trace stop ./trace.zip
browser-buddy profiler start
browser-buddy profiler stop ./profile.json
```

## Visual diffing

```bash
# Compare current page to a saved baseline image:
browser-buddy diff screenshot --baseline ./baselines/pricing.png

# Save the rendered diff to a file:
browser-buddy diff screenshot --baseline ./before.png -o ./diff.png

# Adjust per-pixel color threshold:
browser-buddy diff screenshot --baseline ./before.png -t 0.2

# Snapshot tree diff (current vs. last) and URL comparison:
browser-buddy diff snapshot
browser-buddy diff snapshot --baseline ./before.txt
browser-buddy diff url https://v1.example.com https://v2.example.com
```

PNG is the right format for baselines: pixel-level diffing needs lossless input.

## Global options

Flags that apply to any command:

| Flag | Purpose |
|---|---|
| `--session <name>` | Name the browser session (isolation). |
| `--session-name <name>` | Auto-save/restore state by name (no manual `state save`/`load`). |
| `--state <path>` | Load a state JSON at launch. |
| `--profile <name\|path>` | Use a persistent Chrome profile directory. |
| `--json` | Machine-readable output. |
| `--headed` | Show the browser window. |
| `--cdp <port\|url>` | Attach to an existing Chrome. |
| `--auto-connect` | Auto-discover a running Chrome. |
| `--provider <name>` / `-p` | Cloud browser backend (browserless, browserbase, kernel, agentcore, browseruse, ios). |
| `--proxy <url>` / `--proxy-bypass <hosts>` | Proxy routing. |
| `--headers <json>` | Default headers, scoped to origin. |
| `--executable-path <path>` | Custom Chrome binary. |
| `--extension <path>` | Load an unpacked extension (repeatable). |
| `--ignore-https-errors` | For self-signed certs. |
| `--no-auto-dialog` | Don't auto-accept `alert`/`beforeunload`. |
| `--engine <name>` | Browser engine: `chrome` (default) or `lightpanda`. |
| `--args <args>` | Extra browser launch args, comma/newline separated (e.g. `--no-sandbox`). |
| `--user-agent <ua>` | Custom User-Agent string. |
| `--screenshot-format <fmt>` | `png` or `jpeg`. Needed for JPEG inside `batch` (the wrapper's conversion only covers top-level `screenshot`). |
| `--screenshot-quality <n>` | JPEG quality 0-100 (ignored for PNG). |
| `--screenshot-dir <path>` | Default output directory for screenshots. |
| `--color-scheme <scheme>` | `dark`, `light`, or `no-preference`. |
| `--allowed-domains <list>` | Restrict navigation to these domain patterns. |
| `--allow-file-access` | Allow `file://` URLs to read local files (Chromium only). |
| `--content-boundaries` | Wrap page output in boundary markers. |
| `--max-output <chars>` | Truncate page output to N characters. |
| `--config <path>` | Load a specific config file (see Config file below). |
| `--help` / `-h` | Per-command help. |
| `--version` / `-V` | Print version. |

## Config file

The CLI reads `agent-browser.json` to set defaults, lowest to highest priority:

1. `~/.agent-browser/config.json` (user-level defaults)
2. `./agent-browser.json` (project-level overrides)
3. environment variables
4. CLI flags (override everything)

```json
{ "headed": true, "proxy": "http://localhost:8080", "profile": "./browser-data" }
```

Use `--config <path>` to load a specific file instead. Boolean flags accept an explicit value to override the config (e.g. `--headed false` disables `"headed": true`). A `--config` path that is missing or invalid is a hard error.

## Environment variables

The CLI respects these when the flags aren't passed:

- `AGENT_BROWSER_SESSION`
- `AGENT_BROWSER_SESSION_NAME`
- `AGENT_BROWSER_STATE`
- `AGENT_BROWSER_PROFILE`
- `AGENT_BROWSER_EXECUTABLE_PATH`
- `AGENT_BROWSER_EXTENSIONS`
- `AGENT_BROWSER_PROVIDER`
- `AGENT_BROWSER_HOME`
- `AGENT_BROWSER_STREAM_PORT`
- `AGENT_BROWSER_DEFAULT_TIMEOUT` (operation timeout, ms; default 25000)
- `AGENT_BROWSER_NO_AUTO_DIALOG`
- `AGENT_BROWSER_ENCRYPTION_KEY` (AES-256-GCM key, 64-char hex; encrypts saved state at rest)

For the full env-var list, run `browser-buddy skills get core --full` and search for `AGENT_BROWSER_`.
