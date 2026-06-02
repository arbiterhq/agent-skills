#!/bin/bash
# Bootstrap the browser-buddy skill: vendor the agent-browser binary, download
# Chrome for Testing, and put `browser-buddy` on your PATH so it runs from any
# directory. Safe to re-run; status goes to stderr.
set -e

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
WRAPPER="$REPO_ROOT/plugins/browser-buddy/skills/browser-buddy/bin/browser-buddy"
BIN_DIR="$HOME/.local/bin"
LINK="$BIN_DIR/browser-buddy"

echo "browser-buddy setup" >&2
echo "===================" >&2

# 1. Vendor agent-browser + sharp. The agent-browser postinstall hook downloads
#    the platform-specific native binary.
if ! command -v bun &> /dev/null; then
  echo "error: bun is required but not found. Install it from https://bun.sh and re-run." >&2
  exit 1
fi
echo "Installing workspace dependencies (bun install)..." >&2
(cd "$REPO_ROOT" && bun install)

if [ ! -f "$WRAPPER" ]; then
  echo "error: wrapper not found at $WRAPPER" >&2
  exit 1
fi

# 2. Download Chrome for Testing (idempotent; agent-browser skips if present).
echo "Downloading Chrome for Testing (browser-buddy install)..." >&2
if [ "$(uname -s)" = "Linux" ]; then
  echo "  (Linux: if launch fails for missing system libs, re-run with --with-deps)" >&2
fi
"$WRAPPER" install

# 3. Symlink the wrapper onto PATH (no sudo).
mkdir -p "$BIN_DIR"
ln -sfn "$WRAPPER" "$LINK"
echo "Linked $LINK -> $WRAPPER" >&2

# 4. Warn if ~/.local/bin is not on PATH.
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *)
    echo "" >&2
    echo "WARNING: $BIN_DIR is not on your PATH. Add this to your shell profile:" >&2
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\"" >&2
    echo "Until then, call browser-buddy as $LINK" >&2
    echo "" >&2
    ;;
esac

# 5. Smoke test through the freshly linked binary.
echo "Running smoke test..." >&2
"$LINK" --session smoke open https://example.com \
  && "$LINK" --session smoke snapshot -i \
  && "$LINK" --session smoke close

echo "" >&2
echo "Done. browser-buddy is installed. Try: browser-buddy --session demo open https://example.com" >&2
