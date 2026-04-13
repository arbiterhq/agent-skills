#!/usr/bin/env bun
// browser-buddy entrypoint.
//
// Thin wrapper around the vendored `agent-browser` CLI that adds one piece of
// behavior: by default, screenshots are post-processed from PNG to JPG to keep
// agent context windows lean. The underlying CLI always emits PNG; this script
// converts the result via sharp unless the user opts out.
//
// Opt-out triggers (any one keeps the output as PNG):
//   - the literal flag `--png` anywhere after the `screenshot` subcommand
//   - an output path ending in `.png` (case-insensitive)
//   - no output path at all (CLI default temp file; we don't intervene)
//
// All other args pass through verbatim.

import { existsSync, mkdirSync } from "node:fs";
import { unlink } from "node:fs/promises";
import { tmpdir } from "node:os";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import sharp from "sharp";

const HERE = dirname(fileURLToPath(import.meta.url));

function findAgentBrowser(): string {
  let dir = HERE;
  while (dir !== "/") {
    const candidate = resolve(dir, "node_modules/.bin/agent-browser");
    if (existsSync(candidate)) return candidate;
    dir = dirname(dir);
  }
  console.error(
    "browser-buddy: agent-browser binary not found.\n" +
      "From the agent-skills repo root, run: bun install",
  );
  process.exit(1);
}

const AB = findAgentBrowser();
const args = process.argv.slice(2);

// Find the screenshot subcommand position. agent-browser puts the command after
// any global flags, so we search for the literal token rather than assuming
// args[0]. If it isn't present, pass everything through.
const cmdIdx = args.findIndex((a) => a === "screenshot");

async function passthrough(finalArgs: string[]): Promise<never> {
  const proc = Bun.spawn([AB, ...finalArgs], {
    stdio: ["inherit", "inherit", "inherit"],
  });
  const code = await proc.exited;
  process.exit(code);
}

if (cmdIdx === -1) {
  await passthrough(args);
}

const before = args.slice(0, cmdIdx);
const after = args.slice(cmdIdx + 1);

let forcePng = false;
let outPath: string | undefined;
const passThruArgs: string[] = [];

for (const arg of after) {
  if (arg === "--png") {
    forcePng = true;
  } else if (arg.startsWith("-")) {
    passThruArgs.push(arg);
  } else if (outPath === undefined) {
    outPath = arg;
  } else {
    passThruArgs.push(arg);
  }
}

const isPngPath = outPath ? outPath.toLowerCase().endsWith(".png") : false;
const keepAsPng = forcePng || isPngPath || !outPath;

if (keepAsPng) {
  const cmd = [...before, "screenshot", ...passThruArgs];
  if (outPath) cmd.push(outPath);
  await passthrough(cmd);
}

// Convert path: shoot to temp PNG, sharp-convert to outPath, clean up.
const tmpPng = resolve(
  tmpdir(),
  `buddy-${process.pid}-${Date.now()}.png`,
);
const outDir = dirname(resolve(outPath!));
if (!existsSync(outDir)) mkdirSync(outDir, { recursive: true });

const proc = Bun.spawn(
  [AB, ...before, "screenshot", ...passThruArgs, tmpPng],
  { stdio: ["inherit", "ignore", "inherit"] },
);
const code = await proc.exited;

const cleanup = async () => {
  try {
    await unlink(tmpPng);
  } catch {
    /* already gone */
  }
};

if (code !== 0) {
  await cleanup();
  process.exit(code);
}

try {
  await sharp(tmpPng).jpeg({ quality: 85 }).toFile(outPath!);
} catch (err) {
  console.error(`browser-buddy: JPG conversion failed: ${err}`);
  await cleanup();
  process.exit(1);
}

await cleanup();
process.stderr.write(`\u2713 Screenshot saved to ${outPath}\n`);
process.stdout.write(`${outPath}\n`);
