#!/bin/bash
set -e

# Usage: process-image.sh <input> <operation> [args...]
# Thin wrapper for common ImageMagick operations

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: process-image.sh <input> <operation> [args...]" >&2
  echo "Operations: resize, convert, metadata, crop" >&2
  exit 1
fi

INPUT="$1"
OPERATION="$2"
shift 2

if [ ! -f "$INPUT" ]; then
  echo "Error: File not found: $INPUT" >&2
  exit 1
fi

case "$OPERATION" in
  resize)
    echo "Resizing $INPUT..." >&2
    convert "$INPUT" -resize "$@"
    ;;
  convert)
    echo "Converting $INPUT..." >&2
    convert "$INPUT" "$@"
    ;;
  metadata)
    identify -verbose "$INPUT"
    ;;
  crop)
    echo "Cropping $INPUT..." >&2
    convert "$INPUT" -crop "$@"
    ;;
  *)
    echo "Unknown operation: $OPERATION" >&2
    exit 1
    ;;
esac

echo "Done." >&2
