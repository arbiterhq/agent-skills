#!/bin/bash
set -e

echo "Browser Buddy Setup" >&2
echo "====================" >&2

if command -v agent-browser &>/dev/null; then
  echo "agent-browser is already installed." >&2
  agent-browser --version 2>&1 >&2
else
  echo "Installing agent-browser..." >&2
  npm i -g agent-browser && agent-browser install
  echo "agent-browser installed successfully." >&2
fi
