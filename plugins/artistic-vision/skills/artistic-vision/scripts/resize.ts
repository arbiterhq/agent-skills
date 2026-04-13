/**
 * Imagen resize subcommand — resize images using sharp.
 *
 * Common operation for preparing sprites, thumbnails, or assets.
 * Supports pixel art via --kernel nearest to avoid blurring.
 */

import { Command } from "commander";
import sharp from "sharp";
import { log } from "./log";
import { parseDimensions, writeImageBuffer } from "./util";

export function registerResize(program: Command): void {
  program
    .command("resize")
    .description("Resize an image (WxH, W, xH, or N%)")
    .argument("<input>", "Source image file path")
    .argument("<output>", "Output file path")
    .argument("<dims>", "Target dimensions: WxH, W, xH, or N%")
    .option(
      "--kernel <kernel>",
      "Resize kernel (nearest, cubic, lanczos3)",
      "lanczos3",
    )
    .option(
      "--fit <fit>",
      "Fit mode (cover, contain, fill, inside, outside)",
      "fill",
    )
    .action(
      async (
        input: string,
        output: string,
        dims: string,
        opts: { kernel: string; fit: string },
      ) => {
        const parsed = parseDimensions(dims);
        const img = sharp(input);
        const metadata = await img.metadata();

        let width = parsed.width;
        let height = parsed.height;

        if (parsed.percentage) {
          width = Math.round((metadata.width! * parsed.percentage) / 100);
          height = Math.round((metadata.height! * parsed.percentage) / 100);
        }

        log.info(
          `Resizing: ${metadata.width}x${metadata.height} → ${width ?? "auto"}x${height ?? "auto"} (kernel: ${opts.kernel})`,
        );

        const buffer = await img
          .resize({
            width,
            height,
            kernel: opts.kernel as keyof sharp.KernelEnum,
            fit: opts.fit as keyof sharp.FitEnum,
          })
          .toBuffer();

        writeImageBuffer(output, buffer);
      },
    );
}
