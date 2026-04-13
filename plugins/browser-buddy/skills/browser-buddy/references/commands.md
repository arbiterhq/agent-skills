# Command reference

This is a working reference for the `agent-browser` CLI surface, exposed through the `bin/browser-buddy` wrapper. Command names and flags are the upstream CLI's own; the explanations and examples are ours. Always verify against `bin/browser-buddy <command> --help` for the authoritative flag list in your installed version.

All commands accept the global options listed at the bottom. Append `--json` to any read-style command to get structured output suitable for `jq`.

## Navigation

| Command | Notes |
|---|---|
| `open <url>` | Primary navigation. Aliases: `goto`, `navigate`. Accepts `https://`, `http://`, `file://`, `about:`, `data:`. Bare hosts get `https://` prepended. |
| `back` / `forward` / `reload` | History controls. |
| `close` | Close the session's browser. Aliases: `quit`, `exit`. |
| `connect <port>` | Attach to a running Chrome over CDP. |

```bash
bin/browser-buddy open https://news.ycombinator.com
bin/browser-buddy reload
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
bin/browser-buddy snapshot -i
bin/browser-buddy snapshot -s "main" -d 3
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

## Semantic locators (no snapshot needed)

`find` performs a locate-then-act in a single call. Useful when you know what you're looking for by role, label, or testid.

```bash
bin/browser-buddy find role button click --name "Submit"
bin/browser-buddy find text "Sign in" click
bin/browser-buddy find label "Email" fill "me@example.com"
bin/browser-buddy find testid header-nav hover
bin/browser-buddy find placeholder "Search" type "agent-browser"
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
bin/browser-buddy wait @e5                        # element presence
bin/browser-buddy wait 500                        # milliseconds
bin/browser-buddy wait --text "Dashboard"         # text appears
bin/browser-buddy wait --url "/home"              # URL matches pattern
bin/browser-buddy wait --load networkidle         # load state
bin/browser-buddy wait --fn "document.readyState === 'complete'"
```

Short aliases: `-t`, `-u`, `-l`, `-f`.

## Screenshots and PDF

```bash
bin/browser-buddy screenshot ./out.jpg            # real JPEG (post-processed via sharp)
bin/browser-buddy screenshot --full ./out.jpg     # whole page, JPEG
bin/browser-buddy screenshot ./out.png            # PNG (extension keeps it lossless)
bin/browser-buddy screenshot --png ./out.jpg      # also PNG (--png is the explicit opt-out)
bin/browser-buddy pdf ./page.pdf
```

The underlying CLI always emits PNG. Our wrapper post-processes to JPG by default because PNG tokenizes much more heavily when the image is handed to an LLM. Trigger PNG output by either using a `.png` extension or passing the wrapper-only `--png` flag (it is stripped before the underlying CLI sees it). Use PNG when you need lossless pixels: regression diffing, transparency, icon work.

Omit the path and the wrapper passes through to the underlying CLI, which writes a temp PNG and prints the location. See `recording.md` for video.

## JavaScript

```bash
bin/browser-buddy eval "document.querySelectorAll('a').length"
bin/browser-buddy eval --stdin < script.js
bin/browser-buddy eval -b <base64-encoded-expr>   # avoids shell-quoting pain
```

`eval` returns a serialized result. For complex DOM inspection this is often more flexible than chained `get` calls.

## Network

```bash
bin/browser-buddy network route "**/api/**" --body '{"stub": true}'   # mock responses
bin/browser-buddy network route "**/ads/**" --abort                   # block URLs
bin/browser-buddy network unroute "**/api/**"
bin/browser-buddy network requests --filter graphql
```

## Cookies and storage

```bash
bin/browser-buddy cookies                         # list all
bin/browser-buddy cookies set session abc123
bin/browser-buddy cookies clear
bin/browser-buddy storage local                   # list all
bin/browser-buddy storage local get theme
bin/browser-buddy storage local set theme dark
bin/browser-buddy storage local clear
```

## Tabs, windows, frames, dialogs

```bash
bin/browser-buddy tab                             # list tabs
bin/browser-buddy tab new https://example.com
bin/browser-buddy tab 2                           # switch to index 2
bin/browser-buddy tab close 3
bin/browser-buddy window new

bin/browser-buddy frame "iframe[name=checkout]"   # enter iframe
bin/browser-buddy frame main                      # exit back to main doc

bin/browser-buddy dialog accept "optional text"   # confirm/prompt
bin/browser-buddy dialog dismiss
bin/browser-buddy dialog status
```

By default `alert` and `beforeunload` auto-accept. Pass `--no-auto-dialog` if you need to inspect them first.

## Browser settings

```bash
bin/browser-buddy set viewport 1280 800
bin/browser-buddy set viewport 1280 800 2         # with DPR
bin/browser-buddy set device "iPhone 14"
bin/browser-buddy set geo 37.7749 -122.4194
bin/browser-buddy set offline on
bin/browser-buddy set headers '{"X-Test":"1"}'
bin/browser-buddy set credentials user pass       # HTTP Basic
bin/browser-buddy set media dark reduced-motion
```

## State (sessions, auth, persistence)

```bash
bin/browser-buddy state save ./state.json
bin/browser-buddy state load ./state.json
bin/browser-buddy session list
bin/browser-buddy session show
```

Covered in depth in `sessions.md`.

## Debugging

```bash
bin/browser-buddy console                         # page console log
bin/browser-buddy errors                          # uncaught errors
bin/browser-buddy highlight @e5                   # flash element on screen
bin/browser-buddy inspect                         # open DevTools
bin/browser-buddy trace start
bin/browser-buddy trace stop ./trace.json
bin/browser-buddy profiler start
bin/browser-buddy profiler stop ./profile.json
```

## Batch mode

Pipe multiple commands through `batch` when latency matters.

```bash
cat <<EOF | bin/browser-buddy batch --json
open https://example.com
snapshot -i
screenshot ./out.png
EOF
```

`--bail` aborts on the first failure.

## Global options

Flags that apply to any command:

| Flag | Purpose |
|---|---|
| `--session <name>` | Name the browser session (isolation). |
| `--json` | Machine-readable output. |
| `--headed` | Show the browser window. |
| `--cdp <port\|url>` | Attach to an existing Chrome. |
| `--provider <name>` | Use a cloud browser backend (browserless, browserbase, etc.). Alias `-p`. |
| `--proxy <url>` / `--proxy-bypass <hosts>` | Proxy routing. |
| `--headers <json>` | Default headers for navigation. |
| `--executable-path <path>` | Custom Chrome binary. |
| `--extension <path>` | Load an unpacked extension (repeatable). |
| `--ignore-https-errors` | For self-signed certs. |
| `--help` / `-h` | Per-command help. |
| `--version` / `-V` | Print version. |

## Environment variables

The CLI respects these when the flags aren't passed:

- `AGENT_BROWSER_SESSION`
- `AGENT_BROWSER_EXECUTABLE_PATH`
- `AGENT_BROWSER_EXTENSIONS`
- `AGENT_BROWSER_PROVIDER`
- `AGENT_BROWSER_STREAM_PORT`
- `AGENT_BROWSER_HOME`
