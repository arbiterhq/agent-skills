/**
 * Imagen extract subcommand — AI-guided subject extraction / background removal.
 *
 * Simpler interface than crafting edit prompts manually.
 * Always outputs PNG to preserve transparency.
 */

import { extname } from "path";
import { Command } from "commander";
import {
  getGoogleAI,
  IMAGEN_MODEL,
  extractImageFromResponse,
  type Part,
} from "./google";
import { log } from "./log";
import { loadImageAsBase64, writeImageBuffer } from "./util";
import { describeImage } from "./describe";

export function registerExtract(program: Command): void {
  program
    .command("extract")
    .description("Extract subject from image (remove background)")
    .argument("<input>", "Source image file path")
    .argument("<output>", "Output file path (should be .png for transparency)")
    .option(
      "--subject <description>",
      "What to keep (default: the main subject)",
    )
    .option("--model <model>", "Gemini model override")
    .option("--inspect [question]", "Auto-describe the result")
    .action(
      async (
        input: string,
        output: string,
        opts: { subject?: string; model?: string; inspect?: string | true },
      ) => {
        const model = opts.model ?? IMAGEN_MODEL;
        const subject = opts.subject ?? "the main subject";

        if (extname(output).toLowerCase() !== ".png") {
          log.warn("Output should be .png to preserve transparency.");
        }

        log.dim(`Using ${model}`);
        log.info(`Extracting: "${subject}"`);

        const ai = getGoogleAI();
        const { base64, mimeType } = loadImageAsBase64(input);

        const parts: Part[] = [
          { inlineData: { data: base64, mimeType } },
          {
            text: `Remove the entire background from this image. Keep only ${subject}. Output on a completely transparent background. Preserve the original quality and detail of the subject.`,
          },
        ];

        const response = await ai.models.generateContent({
          model,
          contents: [{ role: "user", parts }],
          config: {
            responseModalities: ["IMAGE", "TEXT"],
          },
        });

        const buffer = extractImageFromResponse(response);
        if (!buffer) {
          log.error("No image in response.");
          const text = response.candidates?.[0]?.content?.parts
            ?.filter((p: { text?: string }) => p.text)
            .map((p: { text?: string }) => p.text)
            .join("\n");
          if (text) {
            log.warn("Model returned text instead:");
            console.log(text);
          }
          process.exit(1);
        }

        writeImageBuffer(output, buffer);

        if (opts.inspect !== undefined) {
          const question =
            typeof opts.inspect === "string" && opts.inspect !== ""
              ? opts.inspect
              : "Describe the extracted subject. Was the background fully removed? Any quality issues?";
          log.dim("\n--- Inspect ---");
          try {
            const description = await describeImage(output, question);
            console.log(description);
          } catch (e) {
            log.warn(`Inspect failed: ${(e as Error).message}`);
          }
        }
      },
    );
}
