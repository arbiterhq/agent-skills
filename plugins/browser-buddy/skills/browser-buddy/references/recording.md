# Screenshots, PDFs, and video

Visual capture is often the fastest way to answer "what does this page actually look like right now."

## Screenshots

```bash
bin/browser-buddy screenshot ./out.jpg              # viewport, post-processed to JPEG
bin/browser-buddy screenshot --full ./out.jpg       # entire scrollable page, JPEG
bin/browser-buddy screenshot ./out.png              # extension forces PNG passthrough
bin/browser-buddy screenshot --png ./out.jpg        # explicit opt-out: PNG even with .jpg path
bin/browser-buddy screenshot                        # omit path: passthrough to CLI's temp PNG
```

**Default is JPG, post-processed.** The vendored `agent-browser` binary always emits PNG. Our wrapper detects the `screenshot` subcommand, runs the underlying capture into a temp PNG, then converts to JPG via sharp at the path you provided. Two ways to opt out: a `.png` (or `.PNG`) file extension, or the wrapper-only `--png` flag (it is stripped before the underlying CLI sees it). Use the PNG path when you need lossless output: transparency, pixel-level regression diffing, icon or logo work, or capturing something you'll overlay programmatically.

A few common patterns:

```bash
# Annotated screenshot with numbered overlays keyed to snapshot refs
# (good for multimodal models reasoning about positions):
bin/browser-buddy screenshot --annotate ./annotated.jpg

# Dark-mode capture:
bin/browser-buddy set media dark
bin/browser-buddy screenshot --full ./dark.jpg

# Mobile viewport capture:
bin/browser-buddy set device "iPhone 14"
bin/browser-buddy open https://example.com
bin/browser-buddy screenshot ./mobile.jpg

# Pixel-perfect baseline for a regression check (PNG is justified here):
bin/browser-buddy screenshot --full ./baselines/pricing.png
```

## PDF

```bash
bin/browser-buddy pdf ./page.pdf
```

The browser's print-to-PDF pipeline. Good for archiving articles, invoices, receipts.

## Video recording

```bash
bin/browser-buddy record start ./demo.webm
# ... run your automation ...
bin/browser-buddy record stop
```

To stop the current take and start a fresh one in a single call:

```bash
bin/browser-buddy record restart ./take2.webm
```

Output is WebM (VP8/VP9). Any modern browser or video player opens it. For smaller files or GIF export, run the result through `ffmpeg` afterward.

Practical notes:

- Recording is session-scoped. Pass the same `--session` to every command if you want one continuous video.
- Long recordings accumulate on disk; `record stop` and clean up.
- Record at a consistent viewport (`set viewport 1280 800` before `record start`) so the result isn't resized mid-video.
- Some headless environments may have codec limitations.

## Visual diffing

`diff screenshot` compares the **current page** to a baseline image — it's not a two-file comparator.

```bash
# First run: capture the baseline.
bin/browser-buddy open https://example.com/pricing
bin/browser-buddy screenshot --full ./baselines/pricing.png

# Later, after a deploy, compare the live page against that baseline:
bin/browser-buddy open https://example.com/pricing
bin/browser-buddy diff screenshot --baseline ./baselines/pricing.png

# Save the rendered diff to a file for review:
bin/browser-buddy diff screenshot --baseline ./baselines/pricing.png -o ./diff.png

# Loosen the per-pixel threshold:
bin/browser-buddy diff screenshot --baseline ./baselines/pricing.png -t 0.2
```

`diff snapshot` does the same for accessibility trees (current vs. last snapshot, or vs. a saved file via `--baseline`). `diff url <a> <b>` compares two URLs side-by-side; add `--screenshot` to also produce a visual diff.

PNG baselines are correct here: pixel-level diffing needs lossless input.

## Choosing which capture

| Goal | Tool |
|---|---|
| Confirm a page loaded correctly | `screenshot` |
| Document a bug visually | `screenshot --full` |
| Archive a page | `pdf` |
| Show a workflow end-to-end | `record start` / `record stop` |
| Detect visual regression | `screenshot` (baseline) + `diff screenshot --baseline` |
| Let a multimodal model reason about layout | `screenshot --annotate` |
