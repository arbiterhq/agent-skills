# Artistic Vision

Image generation, editing, and processing skill combining Nano Banana (Google's Gemini image models) with local image manipulation via Sharp, ImageMagick, and FFmpeg.

## What It Does

- Generate images from text prompts using Gemini image models
- Create transparent PNG assets with automatic background removal
- Edit existing images with AI (style transfer, modifications)
- Resize, crop, convert, and batch process images locally
- Extract image metadata
- Composite and watermark images

## Prerequisites

- `nano-banana` CLI (for AI generation)
- `GEMINI_API_KEY` environment variable
- `imagemagick` and `ffmpeg` (for transparency pipeline)
- `sharp` (optional, for Node.js image processing)

## Usage

This skill is activated automatically when you ask an agent to generate, edit, or process images.

## Structure

```
skills/artistic-vision/
  SKILL.md              # Core skill instructions
  references/           # API docs, Sharp reference, prompt patterns
  scripts/              # Helper scripts for generation and processing
```
