#!/usr/bin/env bun
// Screenshot with region selection and Satty annotation
// Uses ppm format for faster processing (uncompressed vs png)
import { Effect } from "effect";

const program = Effect.sync(() => {
  const slurp = Bun.spawnSync(["slurp"], { stdout: "pipe", stderr: "pipe" });
  if (slurp.exitCode !== 0) process.exit(0); // User cancelled

  const region = new TextDecoder().decode(slurp.stdout).trim();
  if (!region) process.exit(0);

  const grim = Bun.spawnSync(["grim", "-g", region, "-t", "ppm", "-"], { stdout: "pipe" });
  Bun.spawnSync(["satty", "--filename", "-"], {
    stdin:  grim.stdout,
    stdout: "inherit",
    stderr: "inherit",
  });
});

Effect.runSync(program);
