#!/usr/bin/env bun
// Clipboard history selector via cliphist + wofi
import { Effect } from "effect";
import { run } from "../lib/shell";

const program = Effect.sync(() => {
  run(["pkill", "wofi"]);

  const list = Bun.spawnSync(["cliphist", "list"], { stdout: "pipe" });
  if (!list.stdout?.byteLength) process.exit(0);

  const selection = Bun.spawnSync(["wofi", "-dmenu", "-p", "Clipboard:"], {
    stdin:  list.stdout,
    stdout: "pipe",
  });
  if (!selection.stdout?.byteLength || selection.exitCode !== 0) process.exit(0);

  const decoded = Bun.spawnSync(["cliphist", "decode"], {
    stdin:  selection.stdout,
    stdout: "pipe",
  });
  if (!decoded.stdout?.byteLength) process.exit(0);

  Bun.spawnSync(["wl-copy"], { stdin: decoded.stdout });
});

Effect.runSync(program);
