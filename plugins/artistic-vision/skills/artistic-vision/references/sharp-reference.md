# Sharp Reference

<!-- TODO: Flesh out with comprehensive Sharp operations -->

## Installation

```bash
npm i -g sharp-cli
```

## Common Operations

### Resize

```bash
sharp -i input.png -o output.png resize 800 600
```

### Format Conversion

```bash
sharp -i input.png -o output.webp
sharp -i input.jpg -o output.avif
```

### Metadata

```javascript
const sharp = require('sharp');
const metadata = await sharp('input.png').metadata();
```

### Compositing

```javascript
await sharp('background.png')
  .composite([{ input: 'overlay.png', gravity: 'southeast' }])
  .toFile('output.png');
```

## Programmatic API Patterns

<!-- TODO: Add batch processing, pipeline, and streaming patterns -->
