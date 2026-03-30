#!/bin/bash
set -e

echo "Artistic Vision Setup" >&2
echo "======================" >&2

# Check for Nano Banana
if command -v nano-banana &>/dev/null; then
  echo "nano-banana is already installed." >&2
else
  echo "nano-banana not found." >&2
  echo "Install: git clone https://github.com/kingbootoshi/nano-banana-2-skill.git && cd nano-banana-2-skill && bun install && bun link" >&2
fi

# Check for GEMINI_API_KEY
if [ -n "$GEMINI_API_KEY" ]; then
  echo "GEMINI_API_KEY is set." >&2
else
  echo "GEMINI_API_KEY is not set. Get one from https://aistudio.google.com/apikey" >&2
fi

# Check for ImageMagick
if command -v convert &>/dev/null; then
  echo "ImageMagick is installed." >&2
else
  echo "ImageMagick not found. Install: sudo apt install imagemagick (or brew install imagemagick)" >&2
fi

# Check for FFmpeg
if command -v ffmpeg &>/dev/null; then
  echo "FFmpeg is installed." >&2
else
  echo "FFmpeg not found. Install: sudo apt install ffmpeg (or brew install ffmpeg)" >&2
fi

# Check for Sharp
if node -e "require('sharp')" 2>/dev/null; then
  echo "Sharp is installed." >&2
else
  echo "Sharp not found. Install: npm i -g sharp-cli" >&2
fi
