import { Effect } from "effect";
import { run, runLive } from "../lib/shell";
import { c, log } from "../lib/log";
import { NixosBuildError } from "./errors";

const NIXOS_DIR = "/home/fractal-tess/nixos";

export const rebuildNixos = Effect.gen(function* () {
  log.step("Rebuilding NixOS configuration...");

  const hostname = run(["hostname"]).out;
  log.info(`Host: ${hostname}`);
  log.info(`Flake: ${NIXOS_DIR}#${hostname}`);
  console.log();
  console.log(`${c.dim}─────────────────────────────────────────────────────────────${c.reset}`);

  const ok = yield* Effect.promise(() =>
    runLive(["sudo", "nixos-rebuild", "switch", "--flake", `${NIXOS_DIR}#${hostname}`, "--impure"])
  );

  console.log(`${c.dim}─────────────────────────────────────────────────────────────${c.reset}\n`);

  if (!ok) {
    if (run(["git", "diff", "--cached", "--name-only"]).out) {
      log.warning("Unstaging changes due to build failure...");
      run(["git", "reset", "HEAD"]);
    }
    yield* Effect.fail(new NixosBuildError());
  }

  log.success("NixOS rebuild completed successfully");
  const newGen = run(["sudo", "nixos-rebuild", "list-generations"])
    .out.split("\n").find(l => l.endsWith("True"))?.split(/\s+/)[0] ?? "unknown";
  log.info(`Current generation: ${newGen}`);
});
