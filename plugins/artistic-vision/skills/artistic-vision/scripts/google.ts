/**
 * Google GenAI client setup for imagen CLI.
 *
 * Self-contained wrapper around @google/genai with env validation,
 * shared model constants, and structured output helpers.
 */

import { GoogleGenAI, type Part } from "@google/genai";

export { type Part };

/** Validate that an env var exists, or exit with an error. */
function requireEnv(key: string): string {
  const value = process.env[key];
  if (!value) {
    console.error(`Missing required environment variable: ${key}`);
    process.exit(1);
  }
  return value;
}

export function getGoogleAI(): GoogleGenAI {
  const apiKey = requireEnv("GOOGLE_API_KEY");
  return new GoogleGenAI({ apiKey });
}

/** Gemini 3.1 Flash Image — default for all operations. Fast, near-Pro quality. */
export const IMAGEN_MODEL = "gemini-3.1-flash-image-preview";

/** Gemini 3 Pro Image — highest fidelity. Use only when user explicitly requests high quality. */
export const IMAGEN_PRO_MODEL = "gemini-3-pro-image-preview";

/**
 * Extract the first image part from a Gemini response as a base64 buffer.
 * Returns null if the response contains no image data.
 */
export function extractImageFromResponse(
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  response: any,
): Buffer | null {
  const parts = response?.candidates?.[0]?.content?.parts ?? [];
  for (const part of parts) {
    if (part?.inlineData?.data) {
      return Buffer.from(part.inlineData.data, "base64");
    }
  }
  return null;
}

/**
 * Extract text from a Gemini response.
 * Returns null if no text content found.
 */
export function extractTextFromResponse(
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  response: any,
): string | null {
  const text = response.candidates?.[0]?.content?.parts
    ?.filter((p: Part) => p.text)
    .map((p: Part) => p.text)
    .join("\n");
  return text || null;
}

/**
 * Generate structured JSON output from Gemini using a JSON schema.
 * Guarantees the response conforms to the provided schema.
 */
export async function generateStructuredContent<T>(
  model: string,
  parts: Part[],
  jsonSchema: object,
): Promise<T> {
  const ai = getGoogleAI();
  const response = await ai.models.generateContent({
    model,
    contents: [{ role: "user", parts }],
    config: {
      responseMimeType: "application/json",
      responseSchema: jsonSchema as never,
    },
  });

  const text = extractTextFromResponse(response);
  if (!text) {
    throw new Error("No response from model");
  }
  return JSON.parse(text) as T;
}

/**
 * Judge an image against criteria and return a score.
 * Always uses Flash model for speed/cost.
 */
export async function judgeImage(
  imagePath: string,
  criteria: string,
  loadImage: (path: string) => { base64: string; mimeType: string },
): Promise<{ score: number; reasoning: string }> {
  const { base64, mimeType } = loadImage(imagePath);
  return generateStructuredContent<{ score: number; reasoning: string }>(
    IMAGEN_MODEL,
    [
      { inlineData: { data: base64, mimeType } },
      {
        text: `Rate this image on a scale of 1-10 based on the following criteria: ${criteria}\n\nBe critical and specific in your reasoning.`,
      },
    ],
    {
      type: "object",
      properties: {
        score: { type: "number", description: "Score from 1-10" },
        reasoning: {
          type: "string",
          description: "Brief explanation of the score",
        },
      },
      required: ["score", "reasoning"],
    },
  );
}
