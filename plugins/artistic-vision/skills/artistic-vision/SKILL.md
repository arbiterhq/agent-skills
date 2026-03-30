---
name: artistic-vision
description: >-
  Image generation, editing, and processing. Use when the user needs to create
  images from text prompts (via Nano Banana / Gemini image models), edit or
  transform existing images, create transparent assets, resize or convert image
  formats, extract image metadata, do batch image processing, or any visual
  creative task. Triggers include "generate an image", "create a picture",
  "edit this image", "resize", "convert to PNG", "make transparent",
  "create an icon", or "process these images".
---

# Artistic Vision

Image generation via Nano Banana (Google's Gemini image models) and local image processing via Sharp, ImageMagick, and FFmpeg. This skill covers the full pipeline from prompt to final asset.

## Prerequisites

Check for required tools before starting:

```bash
# Image generation
command -v nano-banana || echo "nano-banana not found"

# Image processing (at least one needed)
command -v convert || echo "ImageMagick not found"
command -v ffmpeg || echo "FFmpeg not found"
node -e "require('sharp')" 2>/dev/null || echo "Sharp not found"
```

### Installing Nano Banana

Nano Banana wraps Google's Gemini image generation models. Install from source:

```bash
git clone https://github.com/kingbootoshi/nano-banana-2-skill.git
cd nano-banana-2-skill
bun install && bun link
```

Requires a `GEMINI_API_KEY` environment variable. Get one free from Google AI Studio (https://aistudio.google.com/apikey).

### Installing Image Processing Tools

```bash
# Sharp (Node.js, recommended for programmatic use)
npm i -g sharp-cli

# ImageMagick (needed for transparency pipeline)
sudo apt install imagemagick   # Debian/Ubuntu
brew install imagemagick        # macOS

# FFmpeg (needed for transparency pipeline)
sudo apt install ffmpeg         # Debian/Ubuntu
brew install ffmpeg             # macOS
```

## Image Generation

### Basic Generation

```bash
nano-banana "a serene mountain lake at sunset, photorealistic"
```

Generates a 1024x1024 image and saves it to the current directory.

### Resolution Control

```bash
nano-banana "your prompt" -s 512     # 512x512, fastest
nano-banana "your prompt" -s 1K      # 1024x1024, default
nano-banana "your prompt" -s 2K      # 2048x2048
nano-banana "your prompt" -s 4K      # 4096x4096, slowest
```

### Aspect Ratios

```bash
nano-banana "your prompt" -a 16:9    # Landscape, widescreen
nano-banana "your prompt" -a 9:16    # Portrait, mobile
nano-banana "your prompt" -a 4:3     # Classic
nano-banana "your prompt" -a 21:9    # Ultrawide
nano-banana "your prompt" -a 1:1     # Square (default)
```

### Model Selection

Two models are available:

| Model | Flag | ID | Best for | Relative cost |
|---|---|---|---|---|
| Nano Banana 2 | (default) | `gemini-3.1-flash-image-preview` | Most tasks, fast iteration | 1x |
| Nano Banana Pro | `--model pro` | `gemini-3-pro-image-preview` | Highest quality, better text rendering | 2x |

```bash
nano-banana "your prompt" --model pro
```

Use the default model for iteration and drafts. Switch to Pro for final output or when text rendering quality matters.

### Output Control

```bash
nano-banana "your prompt" -o hero-image -d ~/Pictures
# Saves to ~/Pictures/hero-image.png
```

Without `-o`, filenames are auto-generated from the prompt. Without `-d`, files save to the current directory.

## Transparent Images

The `-t` flag creates transparent PNGs using a 3-step pipeline:

1. Generates the image with a green screen background (prompt is automatically modified)
2. Removes the green screen using FFmpeg colorkey and despill filters
3. Trims whitespace with ImageMagick

```bash
nano-banana "a cartoon robot mascot" -t -o robot
# Output: robot.png with transparent background
```

Requires both `ffmpeg` and `imagemagick` (the `convert` command). If either is missing, the command will fail with a clear error.

Tips for transparent images:
- Use subjects with clear edges (characters, objects, logos)
- Avoid prompts with green elements (they get removed with the background)
- Add "isolated on plain background" to the prompt for cleaner edges
- The Pro model produces cleaner cutouts for complex subjects

## Image Editing with References

Edit existing images by providing a reference:

```bash
nano-banana "make the sky more dramatic" -r photo.jpg
# Outputs an edited version of photo.jpg
```

Multiple references for style transfer or compositing:

```bash
nano-banana "combine these into a collage" -r photo1.jpg -r photo2.jpg
nano-banana "apply this art style to the photo" -r style-reference.png -r source-photo.jpg
```

## Local Image Processing

For operations that do not need AI generation, use Sharp or ImageMagick directly.

### Resize

```bash
# Sharp
sharp -i input.png -o output.png resize 800 600

# ImageMagick
convert input.png -resize 800x600 output.png

# Resize maintaining aspect ratio (fit within bounds)
convert input.png -resize 800x600\> output.png
```

### Format Conversion

```bash
# Sharp
sharp -i input.png -o output.webp

# ImageMagick
convert input.png output.webp
convert input.jpg output.png
```

### Metadata Extraction

```bash
# ImageMagick (detailed)
identify -verbose input.png

# Sharp (programmatic)
node -e "const sharp = require('sharp'); sharp('input.png').metadata().then(m => console.log(JSON.stringify(m, null, 2)))"
```

### Batch Processing

```bash
# Convert all PNGs to WebP
for f in *.png; do convert "$f" "${f%.png}.webp"; done

# Resize all images to max 1200px wide
for f in *.jpg; do convert "$f" -resize 1200x\> "resized/$f"; done
```

### Compositing and Watermarking

```bash
# Add a watermark
composite -gravity southeast -dissolve 30 watermark.png input.png output.png

# Overlay one image on another
composite -geometry +100+50 overlay.png background.png result.png
```

## Cost Awareness

Every Nano Banana generation logs cost to `~/.nano-banana/costs.json`. Check spending:

```bash
nano-banana costs
```

See `references/nano-banana-api.md` for the full cost table and rate limits.

General guidance:
- Default model (Nano Banana 2) is very cheap, suitable for iteration
- Pro model costs roughly 2x, use for final outputs
- Higher resolutions cost more (4K is ~4x the cost of 1K)
- Editing with references costs the same as generation

## Prompt Craft

Good prompts are specific about style, subject, composition, and lighting:

```
"a minimalist logo of a mountain peak, flat design, navy blue on white background, vector style"
```

Avoid vague prompts like "a cool image". See `references/prompt-patterns.md` for a library of effective prompt templates organized by use case.

## Reference Files

- `references/nano-banana-api.md`: Full API reference, cost table, rate limits, model details
- `references/sharp-reference.md`: Sharp operations reference for Node.js image processing
- `references/prompt-patterns.md`: Curated prompt templates by category (logos, photos, illustrations, UI assets)
