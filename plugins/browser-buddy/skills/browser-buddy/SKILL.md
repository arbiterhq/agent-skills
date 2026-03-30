---
name: browser-buddy
description: >-
  Browser automation using the agent-browser CLI. Use when the user needs to
  interact with websites, navigate pages, fill forms, click buttons, take
  screenshots, scrape data, test web apps, do visual regression, or automate
  any browser-based task. Triggers include "open a website", "fill out a form",
  "scrape this page", "take a screenshot", "test this URL", or "automate
  browser actions".
---

# Browser Buddy

Browser automation skill built on Vercel's `agent-browser` CLI, a headless browser tool using Chrome/Chromium via CDP. This skill provides the core interaction workflow plus patterns for scraping, testing, form automation, and visual diffing.

## Prerequisites

`agent-browser` must be installed globally:

```bash
npm i -g agent-browser && agent-browser install
```

Before using any browser commands, check if `agent-browser` is available:

```bash
command -v agent-browser || echo "agent-browser not found"
```

If not installed, tell the user and offer to run the install command.

## Core Workflow

The fundamental pattern is: navigate, snapshot, interact, repeat.

### 1. Open a page

```bash
agent-browser open "https://example.com"
```

Use `--wait-until` to control when the page is considered loaded:
- `load` (default): fires when the page's load event fires
- `networkidle`: fires when there are no more than 2 network connections for 500ms (best for SPAs and dynamic content)
- `domcontentloaded`: fires when the DOM is ready (fastest, but JS may not have run)

```bash
agent-browser open "https://example.com" --wait-until networkidle
```

### 2. Get the accessibility snapshot

```bash
agent-browser snapshot -i
```

The `-i` flag includes interactive element references (@e1, @e2, etc.) in the output. These refs are how you target elements for interaction.

Example output:
```
[document] Example Page
  [heading] Welcome
  [link @e1] Sign In
  [textbox @e2] Email address
  [textbox @e3] Password
  [button @e4] Submit
```

Always take a snapshot before interacting. Element refs change between page loads.

### 3. Interact with elements

```bash
agent-browser click @e1          # Click a link or button
agent-browser fill @e2 "user@example.com"  # Fill a text field
agent-browser select @e5 "option-value"    # Select from a dropdown
agent-browser check @e6           # Check a checkbox
agent-browser hover @e7            # Hover over an element
```

### 4. Capture the page

```bash
agent-browser screenshot page.png              # Full page screenshot
agent-browser screenshot --viewport header.png  # Viewport only
agent-browser pdf output.pdf                   # Save as PDF
```

### 5. Close the session

```bash
agent-browser close
```

Always close when done. The browser daemon persists between commands, so unclosed sessions consume resources.

## Command Chaining

Because the browser persists via a background daemon, commands can be chained with `&&`:

```bash
agent-browser open "https://example.com" && agent-browser screenshot home.png
```

Chain when you do not need intermediate output. Run commands separately when you need to parse snapshot output to determine which elements to interact with.

**Good chaining** (no intermediate parsing needed):
```bash
agent-browser open "https://example.com" && agent-browser screenshot before.png
```

**Do not chain** (need to read snapshot to find the right ref):
```bash
agent-browser open "https://example.com"
agent-browser snapshot -i
# Parse output to find the login button ref
agent-browser click @e3
```

## Session and Authentication Management

Save and restore browser state (cookies, localStorage, sessionStorage) for authentication persistence:

```bash
# After logging in manually or via automation
agent-browser state save ./auth-state.json

# Restore in a future session
agent-browser state load ./auth-state.json
agent-browser open "https://app.example.com/dashboard"
```

See `references/authentication.md` for OAuth flows, 2FA handling, and cookie-based auth patterns.
See `references/session-management.md` for state persistence details and multi-account workflows.

## Scraping Patterns

### Extract structured data from a table

```bash
agent-browser open "https://example.com/products"
agent-browser snapshot -i
# Identify the table structure from the snapshot
agent-browser evaluate "JSON.stringify([...document.querySelectorAll('table tbody tr')].map(row => ({name: row.cells[0].textContent, price: row.cells[1].textContent})))"
```

### Extract all links from a page

```bash
agent-browser evaluate "JSON.stringify([...document.querySelectorAll('a')].map(a => ({text: a.textContent.trim(), href: a.href})))"
```

### Paginated scraping

For multi-page results, loop through pages:

1. Scrape current page data
2. Take a snapshot to find the "Next" button
3. Click it if present
4. Repeat until no "Next" button exists

Use `agent-browser evaluate` for extracting data and `agent-browser snapshot -i` to find navigation controls.

## Visual Regression

Compare page states using screenshots:

```bash
# Capture baseline
agent-browser open "https://example.com" && agent-browser screenshot baseline.png

# After changes
agent-browser open "https://example.com" && agent-browser screenshot current.png

# Diff (requires ImageMagick)
compare baseline.png current.png -compose src diff.png
```

## Form Automation

Multi-step form patterns:

1. Open the form page
2. Snapshot to discover all fields
3. Fill fields in order (some forms reveal fields dynamically)
4. Re-snapshot after filling if the form has conditional fields
5. Submit

```bash
agent-browser open "https://example.com/apply"
agent-browser snapshot -i
agent-browser fill @e1 "Jane Doe"
agent-browser fill @e2 "jane@example.com"
agent-browser select @e3 "california"
# Re-snapshot if the form changed after selection
agent-browser snapshot -i
agent-browser fill @e4 "94102"
agent-browser click @e5  # Submit button
```

See `templates/scrape-recipe.md` for a reusable scraping workflow template.

## Wait Strategies

Choose the right wait strategy based on the page:

| Strategy | Flag | Best for |
|---|---|---|
| Load event | `--wait-until load` | Static pages, server-rendered HTML |
| Network idle | `--wait-until networkidle` | SPAs, pages with async data fetching |
| DOM ready | `--wait-until domcontentloaded` | When you only need the HTML structure |

For elements that appear after JavaScript execution, use explicit waits:

```bash
agent-browser wait "[data-testid='results']" --timeout 10000
```

## Tips

- Always snapshot before interacting. Element refs are ephemeral.
- Use `--wait-until networkidle` for JavaScript-heavy sites.
- Save auth state after login to avoid re-authenticating.
- For scraping, prefer `agent-browser evaluate` with DOM queries over parsing snapshot text.
- Close sessions when done to free resources.
- If a click navigates to a new page, snapshot again before the next interaction.
