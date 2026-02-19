#!/usr/bin/env bun
import { Effect } from "effect";
import { readFileSync } from "fs";
import { run } from "../lib/shell";

const isHidden = (pid: number): boolean => {
  try {
    return readFileSync(`/proc/${pid}/cmdline`, "utf-8").includes("--hidden");
  } catch {
    return false;
  }
};

const waitForDeath = async (pid: number): Promise<void> => {
  const deadline = Date.now() + 2000;
  while (Date.now() < deadline) {
    if (!run(["kill", "-0", String(pid)]).ok) return;
    await Bun.sleep(50);
  }
};

const notify = (msg: string) =>
  run(["notify-send", "Waybar", msg, "-h", "string:x-canonical-private-synchronous:waybar-status"]);

const startWaybar = (hidden: boolean) => {
  const args = hidden ? ["waybar", "--hidden"] : ["waybar"];
  const proc = Bun.spawn(args, { stdin: "ignore", stdout: "ignore", stderr: "ignore" });
  proc.unref();
};

const program = Effect.promise(async () => {
  const pidStr = run(["pgrep", "-x", "waybar"]).out.split("\n")[0];
  const pid = pidStr ? parseInt(pidStr) : null;

  if (pid) {
    const hidden = isHidden(pid);
    run(["kill", "-9", String(pid)]);
    await waitForDeath(pid);

    if (hidden) {
      startWaybar(false);
      notify("🟢 Shown");
    } else {
      startWaybar(true);
      notify("🔴 Hidden");
    }
  } else {
    startWaybar(false);
    notify("🟢 Started");
  }
});

Effect.runPromise(program);
