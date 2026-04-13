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
# Annotated screenshot with numbered overlays (good for agent reasoning about positions):
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

To discard the first take and try again without stopping:

```bash
bin/browser-buddy record restart ./take2.webm
```

Output is WebM (VP8/VP9) by default. Any modern browser or video player opens it. For smaller files, run the result through `ffmpeg` afterward.

Practical notes:

- Recording is session-scoped. If you're capturing a specific flow, run everything under the same `--session`.
- Long recordings accumulate on disk; don't forget to `record stop` and clean up.
- Record at a consistent viewport (`set viewport 1280 800` before `record start`) so the result isn't resized mid-video.

## Visual diffing

`bin/browser-buddy diff screenshot <a> <b>` produces a visual diff between two screenshots. Useful for regression checks. This is one of the cases where PNG is the right format: pixel-level diffing needs lossless input.

```bash
bin/browser-buddy open https://example.com/pricing
bin/browser-buddy screenshot --full ./baselines/pricing.png  # first run

# later, after a deploy:
bin/browser-buddy open https://example.com/pricing
bin/browser-buddy screenshot --full ./current/pricing.png
bin/browser-buddy diff screenshot ./baselines/pricing.png ./current/pricing.png
```

`diff snapshot` and `diff url` do the same for accessibility trees and URL state, respectively.

## Choosing which capture

| Goal | Tool |
|---|---|
| Confirm a page loaded correctly | `screenshot` |
| Document a bug visually | `screenshot --full` |
| Archive a page | `pdf` |
| Show a workflow end-to-end | `record start` / `record stop` |
| Detect visual regression | `screenshot` + `diff screenshot` |
| Let an agent reason about layout | `screenshot --annotate` |
