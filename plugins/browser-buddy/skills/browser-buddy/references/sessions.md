# Sessions, state, and credentials

A session is one browser context: its own cookies, localStorage, sessionStorage, IndexedDB, cache, history, and tabs. Every `agent-browser` command runs against some session.

## Default vs named sessions

Without `--session`, commands share a single default session. That's fine for ad-hoc one-shots; it's a footgun for any task that runs alongside other browser work.

```bash
bin/browser-buddy open https://example.com                           # default session
bin/browser-buddy --session scrape-target open https://example.com   # isolated
bin/browser-buddy --session work-login open https://app.example.com  # also isolated
```

Pick a session name when:

- You want logged-in state for one job not to leak into another.
- You're running concurrent automation against different sites.
- You want to be able to wipe one job's state without affecting the rest.

`AGENT_BROWSER_SESSION=name` sets a default for the shell.

## Three ways to persist auth

### 1. Manual state files (`state save`/`state load`)

Sessions live as long as the browser is open. To carry login state across runs explicitly, persist it.

```bash
# After logging in:
bin/browser-buddy --session work-login state save ./work-state.json

# Later run:
bin/browser-buddy --session work-login state load ./work-state.json
bin/browser-buddy --session work-login open https://app.example.com
```

Or, load state at launch in one shot via the global flag:

```bash
bin/browser-buddy --state ./work-state.json open https://app.example.com
```

State files are JSON (cookies + storage). Not encrypted on disk by default — set `AGENT_BROWSER_ENCRYPTION_KEY` to a 64-char hex key for AES-256-GCM encryption at rest.

### 2. Auto-managed sessions (`--session-name`)

Skip the manual save/load dance entirely. `--session-name <name>` auto-saves on close and auto-restores on next launch.

```bash
bin/browser-buddy --session-name twitter open https://twitter.com
# ... log in interactively ...
bin/browser-buddy --session-name twitter close
# State is saved under ~/.agent-browser/sessions/

# Next time:
bin/browser-buddy --session-name twitter open https://twitter.com
# Already logged in.
```

Set `AGENT_BROWSER_SESSION_NAME=twitter` to apply this to every command in a shell.

### 3. Persistent Chrome profile (`--profile`)

If you want the browser to keep state between runs without managing files at all, point at a persistent profile directory. The OS handles persistence; you don't manage state. Trade-off: profiles are heavier and tied to a single Chrome install path.

```bash
bin/browser-buddy --profile ~/.profiles/myapp open https://app.example.com/login
# ... log in once ...

# All later runs are already authenticated:
bin/browser-buddy --profile ~/.profiles/myapp open https://app.example.com/dashboard
```

Or set `AGENT_BROWSER_PROFILE` to apply globally.

## Importing auth from your own browser

The fastest way to authenticate complex (OAuth/SSO/2FA) flows is to reuse cookies from a Chrome you're already logged into.

```bash
# Start your normal Chrome with remote debugging on:
google-chrome --remote-debugging-port=9222
# (Or: "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --remote-debugging-port=9222 on macOS.)

# Log into the target site in that Chrome window.

# Then grab its state:
bin/browser-buddy --auto-connect state save ./my-auth.json

# Reuse anywhere:
bin/browser-buddy --state ./my-auth.json open https://app.example.com/dashboard
```

`--remote-debugging-port` exposes full browser control on localhost. Only use on trusted machines and close that Chrome when done.

## Credential handling

There is no built-in credential vault in this skill. Two patterns work:

**1. Environment variables in the script.**

```bash
bin/browser-buddy fill @e3 "$LOGIN_EMAIL"
bin/browser-buddy fill @e4 "$LOGIN_PASSWORD"
```

Source the variables from a `.env` file kept out of git, or from a secret manager (`op read`, `aws secretsmanager get-secret-value`, etc.).

**2. HTTP Basic auth.**

```bash
bin/browser-buddy set credentials "$BASIC_USER" "$BASIC_PASS"
bin/browser-buddy open https://internal.example.com
```

For OAuth or SSO flows, log in interactively once, save state, and reuse the state file. Don't try to script the OAuth dance unless you really must.

## Hygiene

- **`.gitignore` state files.** Anything matching `*state*.json`, `*-auth.json`, etc.
- **Delete state files when the job is done** if it's a short-lived task.
- **Use distinct names per environment.** `prod-login` and `staging-login`, not `login`.
- **Wrap secrets in env var indirection** so they don't show up in shell history or process listings.
- **`AGENT_BROWSER_HOME`** points at the CLI's data directory (sessions, profiles). Override per environment if you're isolating CI from local dev.
- **Encrypt at rest:** set `AGENT_BROWSER_ENCRYPTION_KEY` (`openssl rand -hex 32`) when state files contain valuable sessions.

## Concurrency

Two `agent-browser` commands against the same `--session` name run against the same browser. That's usually what you want. If you're running parallel jobs, give each its own session name; otherwise they will fight over tabs and cookies.
