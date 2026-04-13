/**
 * Imagen edit subcommand — edit an image with natural language using Gemini.
 *
 * Supports --inspect for auto-description, and --attempts/--judge for
 * multi-attempt editing with AI quality judging.
 */

import { existsSync, readFileSync, unlinkSync } from "fs";
import { Command } from "commander";
import {
  getGoogleAI,
  IMAGEN_MODEL,
  extractImageFromResponse,
  judgeImage,
  type Part,
} from "./google";
import { log } from "./log";
import { loadImageAsBase64, writeImageBuffer } from "./util";
import { describeImage } from "./describe";

interface EditOpts {
  model?: string;
  inspect?: string | true;
  attempts?: string;
  judge?: string;
}

async function editOnce(
  input: string,
  output: string,
  instruction: string,
  model: string,
): Promise<boolean> {
  const ai = getGoogleAI();
  const { base64, mimeType } = loadImageAsBase64(input);

  const parts: Part[] = [
    { inlineData: { data: base64, mimeType } },
    { text: instruction },
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

export function registerEdit(program: Command): void {
  program
    .command("edit")
    .description("Edit an image with a natural language instruction")
    .argument("<input>", "Source image file path")
    .argument("<output>", "Output file path")
    .argument("<instruction...>", "Editing instruction")
    .option("--model <model>", "Gemini model override")
    .option("--inspect [question]", "Auto-describe the result after editing")
    .option("--attempts <n>", "Edit N times and keep the best")
    .option("--judge <criteria>", "AI judging criteria (requires --attempts)")
    .action(
      async (
        input: string,
        output: string,
        instructionParts: string[],
        opts: EditOpts,
      ) => {
        const model = opts.model ?? IMAGEN_MODEL;
        const instruction = instructionParts.join(" ");
        const attempts = opts.attempts ? parseInt(opts.attempts, 10) : 1;

        log.dim(`Using ${model}`);
        log.info(`Editing: "${instruction}"`);

        if (attempts > 1 && opts.judge) {
          let bestScore = -1;
          let bestFile = "";
          const tempFiles: string[] = [];

          for (let i = 1; i <= attempts; i++) {
            const tempPath = `${output}.attempt${i}.png`;
            tempFiles.push(tempPath);
            log.step(i, attempts, `Editing attempt ${i}...`);

            const ok = await editOnce(input, tempPath, instruction, model);
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

          writeImageBuffer(output, readFileSync(bestFile));
          for (const f of tempFiles) {
            if (existsSync(f)) unlinkSync(f);
          }
          log.success(`Best score: ${bestScore}/10`);
        } else {
          const ok = await editOnce(input, output, instruction, model);
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
              : "Describe what was edited. Note any quality issues, artifacts, or problems.";
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
