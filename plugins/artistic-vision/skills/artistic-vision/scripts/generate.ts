/**
 * Imagen generate subcommand — generate an image from a text prompt using Gemini.
 *
 * Supports --inspect for auto-description, and --attempts/--judge for
 * multi-attempt generation with AI quality judging.
 */

import { existsSync, unlinkSync } from "fs";
import { Command } from "commander";
import {
  getGoogleAI,
  IMAGEN_MODEL,
  extractImageFromResponse,
  judgeImage,
} from "./google";
import { log } from "./log";
import { loadImageAsBase64, writeImageBuffer } from "./util";
import { describeImage } from "./describe";

interface GenerateOpts {
  model?: string;
  inspect?: string | true;
  attempts?: string;
  judge?: string;
}

async function generateOnce(
  prompt: string,
  output: string,
  model: string,
): Promise<boolean> {
  const ai = getGoogleAI();
  const response = await ai.models.generateContent({
    model,
    contents: [{ role: "user", parts: [{ text: prompt }] }],
    config: {
      responseModalities: ["IMAGE", "TEXT"],
    },
  });

  const buffer = extractImageFromResponse(response);
  if (!buffer) {
    const text = response.candidates?.[0]?.content?.parts
      ?.filter((p: { text?: string }) => p.text)
      .map((p: { text?: string }) => p.text)
      .join("\n");
    if (text) {
      log.warn("Model returned text instead:");
      console.log(text);
    }
    return false;
  }

  writeImageBuffer(output, buffer);
  return true;
}

export function registerGenerate(program: Command): void {
  program
    .command("generate")
    .description("Generate an image from a text prompt")
    .argument("<output>", "Output file path (e.g., /tmp/image.png)")
    .argument("<prompt...>", "Text prompt describing the desired image")
    .option("--model <model>", "Gemini model override")
    .option("--inspect [question]", "Auto-describe the result after generation")
    .option("--attempts <n>", "Generate N times and keep the best")
    .option("--judge <criteria>", "AI judging criteria (requires --attempts)")
    .action(
      async (output: string, promptParts: string[], opts: GenerateOpts) => {
        const model = opts.model ?? IMAGEN_MODEL;
        const prompt = promptParts.join(" ");
        const attempts = opts.attempts ? parseInt(opts.attempts, 10) : 1;

        log.dim(`Using ${model}`);
        log.info(`Generating: "${prompt}"`);

        if (attempts > 1 && opts.judge) {
          // Multi-attempt with judging
          let bestScore = -1;
          let bestFile = "";
          const tempFiles: string[] = [];

          for (let i = 1; i <= attempts; i++) {
            const tempPath = `${output}.attempt${i}.png`;
            tempFiles.push(tempPath);
            log.step(i, attempts, `Generating attempt ${i}...`);

            const ok = await generateOnce(prompt, tempPath, model);
            if (!ok) {
              log.warn(`Attempt ${i} failed to produce an image.`);
              continue;
            }

            const result = await judgeImage(
              tempPath,
              opts.judge,
              loadImageAsBase64,
            );
            log.info(`  Score: ${result.score}/10 — ${result.reasoning}`);

            if (result.score > bestScore) {
              bestScore = result.score;
              bestFile = tempPath;
            }
          }

          if (!bestFile) {
            log.error("All attempts failed to produce an image.");
            process.exit(1);
          }

          // Move best to final output, clean up temps
          const { readFileSync } = await import("fs");
          writeImageBuffer(output, readFileSync(bestFile));
          for (const f of tempFiles) {
            if (existsSync(f)) unlinkSync(f);
          }
          log.success(`Best score: ${bestScore}/10`);
        } else {
          // Single attempt
          const ok = await generateOnce(prompt, output, model);
          if (!ok) {
            log.error("No image in response.");
            process.exit(1);
          }
        }

        // Auto-inspect if requested
        if (opts.inspect !== undefined) {
          const question =
            typeof opts.inspect === "string" && opts.inspect !== ""
              ? opts.inspect
              : "Describe what was generated. Note any quality issues, artifacts, or problems.";
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
