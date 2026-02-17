import { Effect } from "effect";
import { run } from "../lib/shell";
import { c } from "../lib/log";

export const showBanner = Effect.sync(() => {
  const hostname     = run(["hostname"]).out;
  const kernel       = run(["uname", "-r"]).out;
  const lastCommit   = run(["git", "log", "-1", "--pretty=format:%h - %s (%cr)"]).out || "No commits";
  const branch       = run(["git", "branch", "--show-current"]).out || "unknown";
  const totalCommits = run(["git", "rev-list", "--count", "HEAD"]).out || "0";
  const localChanges = run(["git", "status", "--porcelain"]).out.split("\n").filter(Boolean).length;
  const currentGen   = run(["sudo", "nixos-rebuild", "list-generations"])
    .out.split("\n").find(l => l.endsWith("True"))?.split(/\s+/)[0] ?? "?";

  process.stdout.write(
    "\x1b[38;2;82;119;195m       ◢██◣\x1b[38;2;127;183;255m   ◥███◣  ◢██◣\n" +
    "\x1b[38;2;82;119;195m       ◥███◣\x1b[38;2;127;183;255m   ◥███◣◢███◤\n" +
    "\x1b[38;2;82;119;195m        ◥███◣\x1b[38;2;127;183;255m   ◥██████◤\n" +
    "\x1b[38;2;82;119;195m    ◢████████████\x1b[48;2;127;183;255m◣\x1b[0m\x1b[38;2;127;183;255m████◤\x1b[38;2;82;119;195m   ◢◣\n" +
    "\x1b[38;2;82;119;195m   ◢██████████████\x1b[48;2;127;183;255m◣\x1b[0m\x1b[38;2;127;183;255m███◣\x1b[38;2;82;119;195m  ◢██◣\n" +
    "\x1b[38;2;127;183;255m        ◢███◤      ◥███◣\x1b[38;2;82;119;195m◢███◤\n" +
    "\x1b[38;2;127;183;255m       ◢███◤        ◥██\x1b[48;2;82;119;195m◤\x1b[0m\x1b[38;2;82;119;195m███◤\n" +
    "\x1b[38;2;127;183;255m◢█████████◤          ◥\x1b[48;2;82;119;195m◤\x1b[0m\x1b[38;2;82;119;195m████████◣\n" +
    "\x1b[38;2;127;183;255m◥████████\x1b[48;2;82;119;195m◤\x1b[0m\x1b[38;2;82;119;195m◣          ◢█████████◤\n" +
    "\x1b[38;2;127;183;255m    ◢███\x1b[48;2;82;119;255m◤\x1b[0m\x1b[38;2;82;119;195m██◣        ◢███◤\n" +
    "\x1b[38;2;127;183;255m   ◢███◤\x1b[38;2;82;119;195m◥███◣      ◢███◤\n" +
    "\x1b[38;2;127;183;255m   ◥██◤  \x1b[38;2;82;119;195m◥███\x1b[48;2;127;183;255m◣\x1b[0m\x1b[38;2;127;183;255m██████████████◤\n" +
    "\x1b[38;2;127;183;255m    ◥◤   \x1b[38;2;82;119;195m◢████\x1b[48;2;127;183;255m◣\x1b[0m\x1b[38;2;127;183;255m████████████◤\n" +
    "\x1b[38;2;82;119;195m        ◢██████◣\x1b[38;2;127;183;255m   ◥███◣\n" +
    "\x1b[38;2;82;119;195m       ◢███◤◥███◤\x1b[38;2;127;183;255m   ◥███◣\n" +
    "\x1b[38;2;82;119;195m       ◥██◤  ◥███◣\x1b[38;2;127;183;255m   ◥██◤\n" +
    "\x1b[0m\n"
  );

  console.log(`${c.bold}${c.cyan}             NixOS Flake Update Manager${c.reset}\n`);

  const row = (label: string, value: string, color: string) =>
    `${c.bold}│${c.reset}  ${label.padEnd(18)} ${color}${value.padEnd(40)}${c.reset}${c.bold}│${c.reset}`;

  console.log(`${c.bold}┌─────────────────────────────────────────────────────────────┐${c.reset}`);
  console.log(`${c.bold}│${c.reset}  ${c.cyan}System Information${c.reset}                                         ${c.bold}│${c.reset}`);
  console.log(`${c.bold}├─────────────────────────────────────────────────────────────┤${c.reset}`);
  console.log(row("Hostname:", hostname, c.green));
  console.log(row("Generation:", currentGen, c.green));
  console.log(row("Kernel:", kernel, c.green));
  console.log(`${c.bold}├─────────────────────────────────────────────────────────────┤${c.reset}`);
  console.log(`${c.bold}│${c.reset}  ${c.cyan}Repository Status${c.reset}                                          ${c.bold}│${c.reset}`);
  console.log(`${c.bold}├─────────────────────────────────────────────────────────────┤${c.reset}`);
  console.log(row("Branch:", branch, c.yellow));
  console.log(row("Total Commits:", totalCommits, c.yellow));
  console.log(row("Local Changes:", `${localChanges} file(s)`, c.yellow));
  console.log(`${c.bold}├─────────────────────────────────────────────────────────────┤${c.reset}`);
  console.log(`${c.bold}│${c.reset}  ${c.cyan}Last Commit${c.reset}                                                ${c.bold}│${c.reset}`);
  console.log(`${c.bold}│${c.reset}  ${c.dim}${lastCommit.substring(0, 57).padEnd(57)}${c.reset}  ${c.bold}│${c.reset}`);
  console.log(`${c.bold}└─────────────────────────────────────────────────────────────┘${c.reset}\n`);
});
