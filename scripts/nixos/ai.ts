import { Effect } from "effect";
import { run } from "../lib/shell";
import { log } from "../lib/log";

const OPENROUTER_KEY_FILE = `${process.env.HOME}/.config/secrets/openrouter_api_key`;
const OPENROUTER_MODEL    = "openai/gpt-5-nano";

const getNextCommitNumber = Effect.sync(() => {
  const lastMsg = run(["git", "log", "-1", "--pretty=format:%s"]).out;
  const match   = lastMsg.match(/^Update #(\d+)/);
  if (match) return parseInt(match[1]) + 1;

  const nums = run(["git", "log", "--pretty=format:%s"]).out
    .split("\n")
    .map(l => l.match(/Update #(\d+)/)?.[1])
    .filter((n): n is string => n !== undefined)
    .map(Number)
    .sort((a, b) => b - a);
  return (nums[0] ?? 0) + 1;
});

export const generateCommitMessage = Effect.gen(function* () {
  const num      = yield* getNextCommitNumber;
  const fallback = `Update #${num}`;

  const diffStat = run(["git", "diff", "--cached", "--stat"]).out
    .split("\n").slice(0, 20).join("\n");
  if (!diffStat) return fallback;

  const apiKey = yield* Effect.promise(() =>
    Bun.file(OPENROUTER_KEY_FILE).text().catch(() => null)
  );

  if (!apiKey) {
    log.warning(`OpenRouter key not found at ${OPENROUTER_KEY_FILE}, using fallback`);
    return fallback;
  }

  const msg = yield* Effect.promise(async () => {
    try {
      const res = await fetch("https://openrouter.ai/api/v1/chat/completions", {
        method: "POST",
        headers: { "Authorization": `Bearer ${apiKey.trim()}`, "Content-Type": "application/json" },
        body: JSON.stringify({
          model: OPENROUTER_MODEL,
          stream: false,
          max_tokens: 2000,
          messages: [{
            role: "user",
            content: `Write a git commit message (max 72 chars, imperative mood, no quotes) for a NixOS config repo. Be brief. Changes:\n\n${diffStat}\n\nRespond with ONLY the commit message, no explanations.`,
          }],
        }),
      });
      if (!res.ok) return null;
      const data = await res.json() as any;
      return (data?.choices?.[0]?.message?.content as string | undefined)
        ?.replace(/\n/g, "").replace(/"/g, "").trim().substring(0, 72) ?? null;
    } catch {
      return null;
    }
  });

  return msg ?? fallback;
});
