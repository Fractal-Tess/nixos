#!/usr/bin/env bun
// Dynamic workspace switcher — swaps workspaces between active monitors
import { Effect } from "effect";
import { run } from "../lib/shell";

interface Monitor { id: number; name: string; width: number; height: number; disabled: boolean; }

const getActiveMonitors = (): string[] => {
  try {
    const monitors: Monitor[] = JSON.parse(run(["hyprctl", "monitors", "-j"]).out);
    return monitors.filter(m => !m.disabled).map(m => m.name);
  } catch {
    return [];
  }
};

const swap = Effect.sync(() => {
  const monitors = getActiveMonitors();
  if (monitors.length >= 2) {
    console.log(`Swapping workspaces between ${monitors[0]} and ${monitors[1]}`);
    run(["hyprctl", "dispatch", "swapactiveworkspaces", monitors[0], monitors[1]]);
  } else if (monitors.length === 1) {
    console.log(`Only one active monitor (${monitors[0]}). Cannot swap.`);
  } else {
    console.log("No active monitors found.");
  }
});

const status = Effect.sync(() => {
  console.log("=== Active Monitor Configuration ===");
  try {
    const monitors: Monitor[] = JSON.parse(run(["hyprctl", "monitors", "-j"]).out);
    for (const m of monitors)
      console.log(`${m.id}: ${m.name} (${m.width}x${m.height}) - Disabled: ${m.disabled}`);
    const active = monitors.filter(m => !m.disabled);
    console.log(`\nActive: ${active.map(m => m.name).join(", ")} (${active.length} total)`);
  } catch {
    console.log("Failed to parse monitor info");
  }
});

const help = Effect.sync(() => {
  console.log("Dynamic Workspace Switcher\n");
  console.log("Usage: workspace-switcher.ts [COMMAND]\n");
  console.log("Commands:");
  console.log("  swap    Swap workspaces between main active monitors (default)");
  console.log("  status  Show current monitor configuration");
  console.log("  help    Show this help message");
});

const program = Effect.gen(function* () {
  switch (process.argv[2] ?? "swap") {
    case "swap":                         yield* swap;   break;
    case "status":                       yield* status; break;
    case "help": case "--help": case "-h": yield* help; break;
    default:
      console.error(`Unknown command: ${process.argv[2]}`);
      yield* help;
      process.exit(1);
  }
});

Effect.runSync(program);
