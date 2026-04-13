---
name: artistic-vision
description: |
  General-purpose AI image intelligence toolkit. Gemini-powered AI operations
  (describe, generate, edit, compare, analyze, ocr, detect, extract, diff) plus
  sharp-powered local manipulation (info, resize, upscale, crop, palette,
  optimize, convert, sprite sheets). Use for any image task: understanding
  contents, creating or editing images, extracting text, detecting objects,
  removing backgrounds, optimizing for web, batch processing, and more.
metadata:
  author: mike
  version: "3.0"
  keywords: image, generation, editing, ocr, detection, optimization, sprites, pixel-art, gemini, sharp
---

# Artistic Vision

General-purpose AI image intelligence toolkit.

## Requirements

Set `GOOGLE_API_KEY` in your environment for any Gemini-powered subcommand. Sharp-powered subcommands run locally and need no API key.

## CLI

```bash
bin/art <subcommand> [args] [options]
```

## Gemini-powered Subcommands (API calls)

| Subcommand                               | Usage                     | What it does                                     |
| ---------------------------------------- | ------------------------- | ------------------------------------------------ |
| `describe <image> [question]`            | Understand image contents | Ask about or describe an image                   |
| `generate <output> <prompt...>`          | Create new images         | Generate image from text prompt                  |
| `edit <input> <output> <instruction...>` | Modify existing images    | Edit image with natural language                 |
| `compare <img1> <img2> [question]`       | Free-text comparison      | Compare two images side by side                  |
| `analyze <image>`                        | Structured analysis       | Local metadata + AI analysis as JSON             |
| `ocr <image>`                            | Extract text              | OCR for screenshots, docs, diagrams, handwriting |
| `detect <image>`                         | Find objects              | Object detection with bounding boxes             |
| `extract <input> <output>`               | Remove background         | AI-guided subject extraction                     |
| `diff <img1> <img2>`                     | Structured diff           | Semantic diff with categorized changes           |
| `batch <subcommand> <glob>`              | Bulk operations           | Run any subcommand across many files             |

### Common Options (Gemini subcommands)

- `--model <model>`: override the default Gemini model
- `--json`: output structured JSON (log messages go to stderr)

### `generate` and `edit` Extra Options

- `--inspect [question]`: auto-describe the result after generation or editing
- `--attempts <n>`: generate N times and keep the best (requires `--judge`)
- `--judge <criteria>`: AI judging criteria for multi-attempt mode

### `extract` Options

- `--subject <description>`: what to keep (default: "the main subject")
- `--inspect [question]`: auto-describe the result

### `detect` Options

- `--what <description>`: what to detect (default: all prominent objects)
- `--draw <output>`: render bounding boxes on the image

### `ocr` Options

- `--plain`: output plain text only (no JSON structure)

### `analyze` Options

- `--local-only`: skip AI analysis, only show local sharp metadata

## Sharp-powered Subcommands (local, no API, instant)

| Subcommand                   | Usage              | What it does                                             |
| ---------------------------- | ------------------ | -------------------------------------------------------- |
| `info <image>`               | Check properties   | Dimensions, format, channels, file size                  |
| `resize <in> <out> <dims>`   | Resize images      | WxH, W, xH, or N%; use `--kernel nearest` for pixel art  |
| `upscale <in> <out> <scale>` | Integer upscale    | Nearest-neighbor (2x, 3x, 4x, 8x) for pixel art or icons |
| `crop <in> <out> <x,y,w,h>`  | Extract regions    | Crop to specific coordinates                             |
| `palette <image>`            | Color palette      | Extract colors as hex values with frequency              |
| `optimize <in> <out>`        | Web optimization   | Smart format, quality, size detection                    |
| `convert <in> <out>`         | Change format      | PNG, JPEG, WebP, AVIF (from extension)                   |
| `sheet split <img>`          | Split sprite sheet | Extract individual frames                                |
| `sheet assemble <dir>`       | Build sprite sheet | Combine frames into sheet                                |
| `sheet analyze <img>`        | Analyze sheet (AI) | Frame detection, animation type, consistency             |

### `optimize` Options

- `--format <fmt>`: force output format (auto-detected if omitted)
- `--quality <n>`: quality 1-100 (default: auto)
- `--max-width <n>`: maximum width in pixels
- `--target-size <kb>`: target file size budget in KB

### `palette` Options

- `--limit <n>`: max colors to show (default: 16)
- `--json`: output as JSON

## Model Selection

- **Default: Flash** (`gemini-3.1-flash-image-preview`): fast, near-Pro quality, used for all operations.
- **Pro** (`gemini-3-pro-image-preview`): highest fidelity, only when the user explicitly requests high quality.
- Pass `--model gemini-3-pro-image-preview` explicitly for maximum quality.

## Examples

```bash
# Describe an image
bin/art describe screenshot.png "What UI components are visible?"

# Generate with auto-inspection
bin/art generate /tmp/logo.png a minimalist logo for a coffee shop --inspect

# Generate with quality judging (3 attempts, keep best)
bin/art generate /tmp/icon.png a flat design app icon --attempts 3 --judge "clean, professional, consistent style"

# Edit an image
bin/art edit photo.jpg /tmp/edited.jpg make it look like a watercolor painting

# Extract subject (remove background)
bin/art extract photo.jpg /tmp/subject.png --subject "the person"

# OCR a screenshot
bin/art ocr screenshot.png --plain

# Detect objects with drawn boxes
bin/art detect photo.jpg --what "all text labels" --draw /tmp/annotated.jpg

# Structured image analysis
bin/art analyze product-photo.jpg --json

# Semantic diff of two versions
bin/art diff v1.png v2.png --json

# Extract color palette
bin/art palette design.png --json

# Optimize for web
bin/art optimize hero.jpg /tmp/hero.webp --max-width 1920 --target-size 200

# Upscale pixel art 4x
bin/art upscale icon-16.png icon-64.png 4

# Batch describe all PNGs
bin/art batch describe "sprites/*.png"

# Batch info on all images
bin/art batch info "assets/**/*.{png,jpg}" --json

# Sprite sheet operations
bin/art sheet split spritesheet.png --frame 32x32 --out frames/
bin/art sheet assemble frames/ --out sheet.png --cols 8
bin/art sheet analyze spritesheet.png --frame 32x32 --json
```

## Tips

- Use `--inspect` on `generate`, `edit`, or `extract` to auto-verify results.
- Use `--json` when piping output to other tools.
- `info` and `palette` are free (no API), so use them liberally.
- For pixel art, always use `upscale` instead of `resize` (nearest-neighbor by default).
- `optimize` auto-detects the best format; use `--target-size` for bandwidth budgets.
- `batch` supports `describe`, `palette`, and `info` today; more subcommands coming.
