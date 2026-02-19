#!/usr/bin/env bun
// Audio sink control for waybar
// Usage:
//   audio-sink.ts        — Toggle mute/unmute current sink
//   audio-sink.ts next   — Switch to next sink
import { Effect } from "effect";
import { run } from "../lib/shell";

const STATE_FILE = "/tmp/audio_sink_state";

const getSinksSection = (status: string): string => {
  const lines = status.split("\n");
  const start = lines.findIndex(l => l.includes("Sinks:"));
  const end   = lines.findIndex((l, i) => i > start && l.includes("Sources:"));
  return lines.slice(start, end > 0 ? end : undefined).join("\n");
};

const getCurrentSink = (section: string): string | null => {
  const line = section.split("\n").find(l => l.includes("*"));
  return line?.match(/\*\s*(\d+)\./)?.[1] ?? null;
};

const getAllSinks = (section: string): string[] =>
  [...section.matchAll(/\s+(\d+)\.\s/g)].map(m => m[1]);

const isMuted = (section: string): boolean => {
  const active = section.split("\n").find(l => l.includes("*"));
  return active?.includes("MUTED") ?? false;
};

const program = Effect.gen(function* () {
  const status  = run(["wpctl", "status"]).out;
  const section = getSinksSection(status);
  const current = getCurrentSink(section);
  const sinks   = getAllSinks(section);

  if (process.argv[2] === "next") {
    if (sinks.length <= 1) { console.log("Only one sink available"); process.exit(1); }
    if (!current)          { console.log("No current sink found");   process.exit(1); }

    yield* Effect.promise(() => Bun.write(STATE_FILE, current));
    const idx  = sinks.indexOf(current);
    const next = sinks[(idx + 1) % sinks.length];
    run(["wpctl", "set-default", next]);
    console.log(`Switched to sink: ${next}`);
    return;
  }

  if (!current) { console.log("No active sink found"); process.exit(1); }

  if (isMuted(section)) {
    run(["wpctl", "set-mute", current, "0"]);
    console.log(`Unmuted sink: ${current}`);
  } else {
    run(["wpctl", "set-mute", current, "1"]);
    console.log(`Muted sink: ${current}`);
  }
});

Effect.runPromise(program);
