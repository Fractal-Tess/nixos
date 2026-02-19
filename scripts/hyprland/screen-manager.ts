#!/usr/bin/env bun
// Screen, brightness, and session manager
// Usage: screen-manager.ts <command> [value]
import { Effect } from "effect";
import { existsSync, readFileSync, writeFileSync, readdirSync } from "fs";
import { run } from "../lib/shell";
import { log } from "../lib/log";

const BRIGHTNESS_CACHE = "/tmp/brightness-cache";
const BRIGHTNESS_STEP  = 10;

// ─── Brightness tools ───────────────────────────────────────────────────────

const hasBrightnessctl = () => run(["which", "brightnessctl"]).ok && existsSync("/sys/class/backlight");
const hasLight         = () => run(["which", "light"]).ok && existsSync("/sys/class/backlight");
const hasDdcutil       = () => run(["which", "ddcutil"]).ok;

const availableMethods = () => {
  const m: string[] = [];
  if (hasBrightnessctl()) m.push("brightnessctl");
  if (hasLight())         m.push("light");
  if (hasDdcutil())       m.push("ddcutil");
  return m.length ? m : ["none"];
};

// ─── Brightness cache ────────────────────────────────────────────────────────

const initCache = () => {
  if (existsSync(BRIGHTNESS_CACHE)) return;
  let initial = 50;
  if (hasBrightnessctl()) {
    const cur = parseInt(run(["brightnessctl", "get"]).out);
    const max = parseInt(run(["brightnessctl", "max"]).out);
    if (cur >= 0 && max > 0) initial = Math.round((cur * 100) / max);
  } else if (hasLight()) {
    const cur = parseInt(run(["light", "-G"]).out);
    if (!isNaN(cur)) initial = cur;
  } else if (hasDdcutil()) {
    const detect  = run(["ddcutil", "detect"]).out;
    const busMatch = detect.match(/I2C bus.*?-(\d+)/);
    if (busMatch) {
      const vcp = run(["ddcutil", "--bus", busMatch[1], "getvcp", "10"]).out;
      const val = parseInt(vcp.match(/current value =\s*(\d+)/)?.[1] ?? "");
      if (!isNaN(val)) initial = val;
    }
  }
  writeFileSync(BRIGHTNESS_CACHE, String(initial));
};

const clamp = (v: number) => Math.max(0, Math.min(100, v));

const getCachedBrightness = (): number => {
  initCache();
  const val = parseInt(readFileSync(BRIGHTNESS_CACHE, "utf-8").trim());
  return isNaN(val) || val < 0 || val > 100 ? 50 : val;
};

const getDdcutilBuses = (): string[] =>
  run(["ddcutil", "detect"]).out
    .split("\n")
    .filter(l => l.includes("I2C bus"))
    .map(l => l.match(/I2C bus.*?-(\d+)/)?.[1])
    .filter((b): b is string => Boolean(b));

const setBrightnessDdcutil = (value: number) => {
  for (const bus of getDdcutilBuses()) {
    const proc = Bun.spawn(
      ["ddcutil", "--bus", bus, "--sleep-multiplier", ".1", "setvcp", "10", String(value)],
      { stdin: "ignore", stdout: "ignore", stderr: "ignore" }
    );
    proc.unref();
  }
};

const setBrightness = (value: number) => {
  const v = clamp(value);
  writeFileSync(BRIGHTNESS_CACHE, String(v));
  if (hasBrightnessctl()) run(["brightnessctl", "set", `${v}%`]);
  if (hasLight())         run(["light", "-S", String(v)]);
  if (hasDdcutil())       setBrightnessDdcutil(v);
};

// ─── Brightness JSON (for waybar) ────────────────────────────────────────────

const brightnessJson = (subdued = false) => {
  const b       = getCachedBrightness();
  const methods = availableMethods();
  const suffix  = methods[0] === "none" ? " (no control)" : ` (${methods.join(", ")})`;
  const tooltip = `Brightness: ${b}%${suffix}\\rScroll: adjust brightness\\rLeft click: turn screens off\\rRight click: set to 100%`;
  if (subdued) {
    console.log(JSON.stringify({ percentage: b, text: `brightness: ${b}%`, tooltip, class: "brightness-subdued" }));
  } else {
    console.log(JSON.stringify({ percentage: b, text: `☀ ${b}%`, tooltip, class: "brightness" }));
  }
};

// ─── Screen DPMS ─────────────────────────────────────────────────────────────

const getHyprInstances = (): string[] => {
  const dir = `${process.env.XDG_RUNTIME_DIR}/hypr`;
  if (!existsSync(dir)) return [];
  try { return readdirSync(dir).filter(s => /^[a-zA-Z0-9]+$/.test(s)); }
  catch { return []; }
};

const dpms = (state: "on" | "off"): boolean => {
  const savedSig = process.env.HYPRLAND_INSTANCE_SIGNATURE;
  for (const sig of getHyprInstances()) {
    process.env.HYPRLAND_INSTANCE_SIGNATURE = sig;
    if (run(["hyprctl", "dispatch", "dpms", state]).ok) {
      process.env.HYPRLAND_INSTANCE_SIGNATURE = savedSig;
      return true;
    }
  }
  process.env.HYPRLAND_INSTANCE_SIGNATURE = savedSig;
  return false;
};

const screenOffFallback = () => {
  if (hasDdcutil())       { run(["ddcutil", "setvcp", "10", "0"]);   return; }
  if (hasBrightnessctl()) { run(["brightnessctl", "set", "0"]);       return; }
  if (hasLight())         { run(["light", "-S", "0"]);                return; }
  run(["xset", "dpms", "force", "off"]);
};

const screenOnFallback = () => {
  if (hasDdcutil())       { run(["ddcutil", "setvcp", "10", "100"]);  return; }
  if (hasBrightnessctl()) { run(["brightnessctl", "set", "100%"]);    return; }
  if (hasLight())         { run(["light", "-S", "100"]);              return; }
  run(["xset", "dpms", "force", "on"]);
};

const screenOff = () => { if (!dpms("off")) screenOffFallback(); };
const screenOn  = () => { if (!dpms("on"))  screenOnFallback();  };

// ─── Session ────────────────────────────────────────────────────────────────

const getActiveSession = (): string => {
  const line = run(["loginctl", "list-sessions", "--no-legend"]).out
    .split("\n").find(l => l.includes("seat0"));
  return line?.trim().split(/\s+/)[0] ?? "";
};

const isSessionLocked = (id: string): boolean => {
  if (!id) return false;
  const line = run(["loginctl", "show-session", id]).out
    .split("\n").find(l => l.startsWith("LockedHint="));
  return line?.split("=")[1]?.trim() === "yes";
};

const lockSession = () => {
  const id = getActiveSession();
  if (!id) { log.error("No active session found"); return; }
  run(["loginctl", "lock-session", id]);
  log.success("Session locked");
};

const unlockSession = () => {
  const id = getActiveSession();
  if (!id) { log.error("No active session found"); return; }
  run(["loginctl", "unlock-session", id]);
  log.success("Session unlocked");
};

// ─── Status / Help ───────────────────────────────────────────────────────────

const showStatus = () => {
  log.info("=== Screen and Session Status ===");
  const id = getActiveSession();
  if (id) {
    console.log(`Active Session ID: ${id}`);
    console.log(`Session Locked:    ${isSessionLocked(id) ? "Yes" : "No"}`);
    const state = run(["loginctl", "show-session", id]).out
      .split("\n").find(l => l.startsWith("State="))?.split("=")[1] ?? "unknown";
    console.log(`Session State:     ${state}`);
  } else {
    console.log("No active graphical session found");
  }
  const b       = getCachedBrightness();
  const methods = availableMethods();
  console.log(`Brightness:        ${b}% (${methods.join(", ")})`);
};

const showHelp = () => {
  console.log(`Universal Screen and Brightness Manager

Usage: screen-manager.ts [COMMAND] [VALUE]

SCREEN COMMANDS:
  off, off-screen         Turn screen off
  on, on-screen           Turn screen on
  toggle                  Toggle screen on/off

SESSION COMMANDS:
  lock                    Lock current session
  unlock                  Unlock current session
  lock-toggle             Toggle session lock state

BRIGHTNESS COMMANDS:
  bright-get              Get current brightness (from cache)
  bright-set <0-100>      Set brightness to specific percentage
  bright-up [step]        Increase brightness (default: ${BRIGHTNESS_STEP}%)
  bright-down [step]      Decrease brightness (default: ${BRIGHTNESS_STEP}%)
  bright-json             Output JSON for waybar
  bright-json-subdued     Output subdued JSON for waybar

UTILITY COMMANDS:
  status                  Show current status
  help                    Show this help message`);
};

// ─── Main ────────────────────────────────────────────────────────────────────

const program = Effect.sync(() => {
  const [, , action = "help", arg2] = process.argv;

  switch (action) {
    case "off": case "off-screen": screenOff(); break;
    case "on":  case "on-screen":  screenOn();  break;

    case "toggle": {
      const id = getActiveSession();
      isSessionLocked(id) ? screenOn() : screenOff();
      break;
    }

    case "lock":        lockSession();   break;
    case "unlock":      unlockSession(); break;
    case "lock-toggle": {
      const id = getActiveSession();
      isSessionLocked(id) ? unlockSession() : lockSession();
      break;
    }

    case "bright-get": console.log(getCachedBrightness()); break;

    case "bright-set": {
      const v = parseInt(arg2 ?? "");
      if (isNaN(v) || v < 0 || v > 100) { log.error("bright-set requires 0-100"); process.exit(1); }
      setBrightness(v);
      log.success(`Brightness set to ${v}%`);
      break;
    }

    case "bright-up": {
      const step = parseInt(arg2 ?? String(BRIGHTNESS_STEP));
      if (isNaN(step) || step < 1) { log.error("Step must be ≥ 1"); process.exit(1); }
      const cur = getCachedBrightness();
      const next = clamp(cur + step);
      setBrightness(next);
      log.success(`Brightness ${cur}% → ${next}%`);
      break;
    }

    case "bright-down": {
      const step = parseInt(arg2 ?? String(BRIGHTNESS_STEP));
      if (isNaN(step) || step < 1) { log.error("Step must be ≥ 1"); process.exit(1); }
      const cur = getCachedBrightness();
      const next = clamp(cur - step);
      setBrightness(next);
      log.success(`Brightness ${cur}% → ${next}%`);
      break;
    }

    case "bright-json":         brightnessJson(false); break;
    case "bright-json-subdued": brightnessJson(true);  break;

    case "brightness": {
      const v = parseInt(arg2 ?? "");
      if (isNaN(v)) { log.error("Brightness value required"); process.exit(1); }
      setBrightness(v);
      break;
    }

    case "status": showStatus(); break;
    case "help": case "--help": case "-h": showHelp(); break;

    default: {
      const asNum = parseInt(action);
      if (!isNaN(asNum) && asNum >= 0 && asNum <= 100) {
        setBrightness(asNum);
      } else {
        log.error(`Unknown command: ${action}`);
        showHelp();
        process.exit(1);
      }
    }
  }
});

Effect.runSync(program);
