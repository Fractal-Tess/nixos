#!/usr/bin/env bun
// Laptop lid event handler
// Usage: lid-handler.ts close | open
import { Effect } from "effect";
import { appendFileSync } from "fs";
import { run } from "../lib/shell";

const LAPTOP_MONITOR = "eDP-1";
const LOG_FILE       = "/tmp/lid-close-handler.log";

const logMsg = (msg: string) => {
  const ts = new Date().toISOString().replace("T", " ").slice(0, 19);
  try { appendFileSync(LOG_FILE, `[${ts}] ${msg}\n`); } catch { /* ignore */ }
};

interface Monitor { name: string; disabled: boolean; }

const getMonitors = (): Monitor[] => {
  try { return JSON.parse(run(["hyprctl", "monitors", "-j"]).out); }
  catch { return []; }
};

const getExternalCount = (monitors: Monitor[]) =>
  monitors.filter(m => !m.name.startsWith("e") && !m.disabled).length;

const isLaptopEnabled = (monitors: Monitor[]) => {
  const laptop = monitors.find(m => m.name === LAPTOP_MONITOR);
  return laptop ? !laptop.disabled : false;
};

const notify = (title: string, msg: string) =>
  run(["notify-send", title, msg, "-t", "3000"]);

const close = Effect.promise(async () => {
  const monitors = getMonitors();
  const external = getExternalCount(monitors);
  const laptopOn = isLaptopEnabled(monitors);

  logMsg(`Lid close event. External monitors: ${external}, Laptop enabled: ${laptopOn}`);

  if (laptopOn) {
    logMsg(`Disabling ${LAPTOP_MONITOR}`);
    run(["hyprctl", "keyword", "monitor", `${LAPTOP_MONITOR}, disable`]);
    notify("Lid Closed", "Laptop screen disabled");
  }

  if (external === 0) {
    logMsg("No external monitors — locking and suspending");
    await Bun.sleep(500);

    const hyprlock = Bun.spawn(["hyprlock"], { stdin: "ignore", stdout: "ignore", stderr: "ignore" });
    hyprlock.unref();

    await Bun.sleep(2000);
    logMsg("Suspending system");

    if (run(["loginctl", "suspend"]).ok) return;
    logMsg("Cannot suspend — insufficient privileges");
    notify("Suspend Failed", "Cannot suspend — insufficient privileges");
  } else {
    logMsg(`${external} external monitor(s) — system remains unlocked`);
  }
});

const open = Effect.sync(() => {
  logMsg("Lid open event");
  run(["hyprctl", "keyword", "monitor", `${LAPTOP_MONITOR}, preferred, auto, 1`]);
  run(["hyprctl", "reload"]);
  notify("Lid Opened", "Laptop screen enabled");

  const updated = getExternalCount(getMonitors());
  logMsg(`Lid opened with ${updated} external monitor(s)`);
});

const program = Effect.gen(function* () {
  switch (process.argv[2]) {
    case "close": yield* close; break;
    case "open":  yield* open;  break;
    default:
      console.error("Usage: lid-handler.ts close | open");
      process.exit(1);
  }
});

Effect.runPromise(program);
