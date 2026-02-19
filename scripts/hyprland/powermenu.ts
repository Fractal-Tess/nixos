#!/usr/bin/env bun
// Power menu via wofi
import { Effect } from "effect";
import { run } from "../lib/shell";

const ENTRIES = "⇠ Logout\n⏾ Suspend\n⭮ Reboot\n⏻ Shutdown";

const program = Effect.sync(() => {
  run(["pkill", "wofi"]);

  const selection = Bun.spawnSync(
    ["wofi", "--width", "250", "--height", "210", "-p", "Power Menu:", "--dmenu", "--cache-file", "/dev/null"],
    { stdin: new TextEncoder().encode(ENTRIES), stdout: "pipe" }
  );
  if (!selection.stdout?.byteLength || selection.exitCode !== 0) process.exit(0);

  const chosen = new TextDecoder().decode(selection.stdout).trim().split(/\s+/)[1]?.toLowerCase();

  switch (chosen) {
    case "logout":
      if (run(["hyprctl", "version"]).ok) run(["hyprctl", "dispatch", "exit"]);
      else run(["loginctl", "terminate-user", process.env.USER ?? ""]);
      break;
    case "suspend":  run(["systemctl", "suspend"]);  break;
    case "reboot":   run(["systemctl", "reboot"]);   break;
    case "shutdown": run(["systemctl", "poweroff"]); break;
  }
});

Effect.runSync(program);
