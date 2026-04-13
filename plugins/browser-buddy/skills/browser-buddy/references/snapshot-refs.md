# Snapshots and refs

The snapshot-ref pattern is what separates `agent-browser` from Puppeteer or Playwright scripts. Understanding it is the difference between efficient automation and a script that thrashes.

## What a snapshot is

A snapshot is the browser's accessibility tree, rendered as a compact structural listing of the page's visible and interactive elements. Every element gets a stable-for-this-snapshot identifier like `@e1`, `@e2`, `@e47`. Alongside each ref you get enough metadata (role, name, text, key attributes) to pick the one you want.

```
bin/browser-buddy snapshot -i
```

produces something like:

```
@e1 link "Home"
@e2 link "About"
@e3 input[type=search] "Search the site"
@e4 button "Go"
@e5 heading level=1 "Latest news"
...
```

## Why this exists

Selector-based scripts are expensive for agents:

- Full DOM can be thousands of tokens.
- Selectors are fragile. A class rename breaks every script that used it.
- Structure-aware LLMs pick well-named targets more reliably than they pick CSS selectors.

A snapshot trades a one-shot browser operation for a small structured list. Picking `@e3` and acting on it is cheaper and more reliable than reasoning about `input[name="q"].search__field--primary`.

## Snapshot variants

| Form | When |
|---|---|
| `snapshot` | Full tree. Verbose. Use when you need non-interactive elements (headings, static text). |
| `snapshot -i` | Interactive only (links, buttons, inputs, controls). Default pick. |
| `snapshot -c` | Compact output. |
| `snapshot -d <n>` | Depth-limited. Good for huge pages. |
| `snapshot -s <selector>` | Scoped to a region. Use when you already know the container. |
| `snapshot --json` | Structured output for `jq` or scripts. |

## The lifecycle rule

**Refs are scoped to the snapshot that produced them.** Anything that mutates the DOM can invalidate refs:

- Navigation (`open`, `back`, `forward`, link clicks that route).
- Clicks that open menus, modals, or dropdowns.
- Form submissions.
- Async content loading (infinite scroll, live search).
- Framework re-renders triggered by state changes.

If you try to use a stale ref you get `Ref not found`. The fix is always the same: re-snapshot.

The mental model: `snapshot` is a photograph. You can point at anything in the photo. The moment the page changes, your photo is out of date.

## A typical loop

```bash
bin/browser-buddy open https://app.example.com/login
bin/browser-buddy snapshot -i

# read output, pick refs
bin/browser-buddy fill @e4 "user@example.com"
bin/browser-buddy fill @e5 "hunter2"
bin/browser-buddy click @e6

# page navigated, refs are dead
bin/browser-buddy wait --url "/dashboard"
bin/browser-buddy snapshot -i

# now interact with the logged-in UI
bin/browser-buddy click @e3
```

## When refs are the wrong tool

Three cases where you should skip the snapshot:

1. **You know what you want by role/label/testid.** Use `find`:
   ```bash
   bin/browser-buddy find role button click --name "Save"
   bin/browser-buddy find testid submit-cta click
   ```
   `find` is a single atomic operation. No stale-ref risk.

2. **You need computed DOM state.** Use `eval`:
   ```bash
   bin/browser-buddy eval "Array.from(document.querySelectorAll('article')).map(a => a.dataset.id)"
   ```

3. **You're doing a quick visual check.** Go straight to `screenshot --full` and look at the image.

## Scoping tricks

Huge pages produce huge snapshots. Narrow down:

```bash
bin/browser-buddy snapshot -i -s "main"             # just the main region
bin/browser-buddy snapshot -i -s "form.checkout"    # just the checkout form
bin/browser-buddy snapshot -i -d 2                  # shallow tree
```

Scoping also helps refs survive: a tighter snapshot is faster to re-run after a local DOM change.

## Iframes

Single-level iframes are inlined into the snapshot automatically. Refs inside an iframe carry their frame context, so `click @e12` works even if `@e12` is in a sandboxed frame. For deeper iframe nesting, switch with `bin/browser-buddy frame <selector>` first, then snapshot inside the frame.

## Debugging a stuck ref

If an action fails with `Ref not found`:

1. Re-snapshot, then retry. 95% of cases.
2. If the ref is actually still there but the action fails, check `is visible @ref` and `is enabled @ref`.
3. If the element appears only after scroll, run `scrollintoview @ref` after re-snapshotting.
4. If the element is inside a closed details/accordion/modal, open the container first, then re-snapshot.
