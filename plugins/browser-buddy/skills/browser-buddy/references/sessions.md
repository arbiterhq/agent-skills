# Sessions, state, and credentials

A session is one browser context: its own cookies, localStorage, sessionStorage, IndexedDB, cache, history, and tabs. Every `agent-browser` command runs against some session.

## Default vs named sessions

Without `--session`, commands share a single default session. That's fine for ad-hoc one-shots; it's a footgun for any task that runs alongside other browser work.

```bash
bin/browser-buddy open https://example.com                           # default session
bin/browser-buddy --session scrape-target open https://example.com   # isolated
bin/browser-buddy --session work-login open https://app.example.com  # also isolated, separate from above
```

Pick a session name when:

- You want logged-in state for one job not to leak into another.
- You're running concurrent automation against different sites.
- You want to be able to wipe one job's state without affecting the rest.

You can also set `AGENT_BROWSER_SESSION` in the environment to make a name the default for the shell.

## State save and load

Sessions live as long as the browser is open. To carry login state across runs, persist it.

```bash
# After logging in interactively or programmatically:
bin/browser-buddy --session work-login state save ./work-state.json

# On a later run, before doing anything else:
bin/browser-buddy --session work-login state load ./work-state.json
bin/browser-buddy --session work-login open https://app.example.com
```

The state file is JSON containing cookies and storage data. It is not encrypted on disk by default. Treat it like a credential.

## Persistent profile (alternative)

If you want the browser to keep state between runs without manual save/load, point at a persistent profile directory. Then the OS handles persistence and you don't manage state files at all. Trade-off: profiles are heavier and tied to a single Chrome install path.

## Credential handling

There is no built-in credential vault. Two patterns work:

**1. Environment variables in the script.**

```bash
bin/browser-buddy fill @e3 "$LOGIN_EMAIL"
bin/browser-buddy fill @e4 "$LOGIN_PASSWORD"
```

Source the variables from a `.env` file you keep out of git, or from a secret manager (`op read`, `aws secretsmanager get-secret-value`, etc.).

**2. HTTP Basic auth.**

```bash
bin/browser-buddy set credentials "$BASIC_USER" "$BASIC_PASS"
bin/browser-buddy open https://internal.example.com
```

For OAuth or SSO flows, log in interactively once, save state, and reuse the state file. Don't try to script the OAuth dance unless you really must.

## Listing and inspecting sessions

```bash
bin/browser-buddy session list                  # all sessions known to the CLI
bin/browser-buddy session show                  # info about the current one
bin/browser-buddy --session work-login close    # tear it down explicitly
```

## Hygiene

- **`.gitignore` state files.** Anything matching `*state*.json`, `*-auth.json`, etc.
- **Delete state files when the job is done** if it's a short-lived task.
- **Use distinct names per environment.** `prod-login` and `staging-login`, not `login`.
- **Wrap secrets in env var indirection** so they don't show up in shell history or process listings.
- **`AGENT_BROWSER_HOME`** points at the CLI's data directory (sessions, profiles). Override per-environment if you're isolating CI from local dev.

## Concurrency

Two `agent-browser` commands against the same session name run against the same browser. That's usually what you want. If you're running parallel jobs, give each its own session name; otherwise they will fight over tabs and cookies.
