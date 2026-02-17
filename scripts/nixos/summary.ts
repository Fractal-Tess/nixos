import { Effect } from "effect";
import { run } from "../lib/shell";
import { c, log } from "../lib/log";

export const showSummary = (hadChanges: boolean, pushed: boolean) => Effect.sync(() => {
  log.header("Update Complete");

  const newGen     = run(["sudo", "nixos-rebuild", "list-generations"])
    .out.split("\n").find(l => l.endsWith("True"))?.split(/\s+/)[0] ?? "?";
  const lastCommit = run(["git", "log", "-1", "--pretty=format:%h - %s"]).out || "None";

  console.log(c.green +
    "    ╔═══════════════════════════════════════════╗\n" +
    "    ║                                           ║\n" +
    "    ║   ✓ System successfully updated!          ║\n" +
    "    ║                                           ║\n" +
    "    ╚═══════════════════════════════════════════╝" +
    c.reset + "\n"
  );

  console.log(`  ${c.bold}Summary:${c.reset}`);
  console.log(`  • Generation: ${c.green}${newGen}${c.reset}`);
  console.log(`  • Last commit: ${c.cyan}${lastCommit}${c.reset}`);
  if (hadChanges) {
    if (pushed) console.log(`  • Changes: ${c.green}Committed and pushed${c.reset}`);
    else        console.log(`  • Changes: ${c.yellow}Committed (push pending)${c.reset}`);
  } else {
    console.log(`  • Changes: ${c.dim}No local changes${c.reset}`);
  }
  console.log();

  console.log(`  ${c.bold}Recent Generations:${c.reset}`);
  console.log(`  ${c.dim}  ${"Gen".padEnd(4)}  ${"Built".padEnd(19)}  Commit${c.reset}`);

  const genLines = run(["sudo", "nixos-rebuild", "list-generations"])
    .out.split("\n").slice(1).filter(Boolean).slice(0, 5);

  for (const line of genLines) {
    const parts     = line.trim().split(/\s+/);
    const gen       = parts[0] ?? "";
    const buildDate = `${parts[1]} ${parts[2]}`;
    const isCurrent = parts[parts.length - 1] === "True";
    const commitMsg = run(["git", "log", "-1", "--format=%s", `--until=${buildDate}`])
      .out.substring(0, 45);

    if (isCurrent) {
      console.log(`  ${c.green}→ ${gen.padEnd(4)}  ${buildDate.padEnd(19)}  ${commitMsg}${c.reset}`);
    } else {
      console.log(`  ${c.dim}  ${gen.padEnd(4)}  ${buildDate.padEnd(19)}  ${commitMsg}${c.reset}`);
    }
  }
  console.log();
});
