# Nano Banana API Reference

<!-- TODO: Flesh out with full API details -->

## Models

| Model | ID | Notes |
|---|---|---|
| Nano Banana 2 | `gemini-3.1-flash-image-preview` | Default, fast, cheap |
| Nano Banana Pro | `gemini-3-pro-image-preview` | Highest quality, 2x cost |

## CLI Flags

| Flag | Description | Example |
|---|---|---|
| `-s` | Resolution | `-s 2K` |
| `-a` | Aspect ratio | `-a 16:9` |
| `-t` | Transparent background | `-t` |
| `-r` | Reference image | `-r source.png` |
| `-o` | Output filename | `-o hero` |
| `-d` | Output directory | `-d ~/Pictures` |
| `--model` | Model selection | `--model pro` |

## Cost Table

<!-- TODO: Add current pricing -->

Costs are logged to `~/.nano-banana/costs.json`.

## Rate Limits

<!-- TODO: Add current rate limits from Google AI Studio -->
