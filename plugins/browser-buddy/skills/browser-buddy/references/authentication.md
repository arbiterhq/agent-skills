# Authentication Patterns

<!-- TODO: Flesh out with detailed patterns -->

## OAuth Flows

Patterns for automating OAuth login flows with agent-browser.

## Cookie-Based Auth

Saving and restoring cookie-based sessions.

## Two-Factor Authentication

Handling 2FA prompts during automated login. Strategies include:
- TOTP code entry from environment variables
- Pausing for manual 2FA completion
- Using saved session state to skip 2FA on known devices

## API Key / Bearer Token Injection

Injecting auth headers for API-driven pages.
