#!/usr/bin/env bun

import { Effect, pipe } from "effect";
import { existsSync } from "fs";
import { run } from "../lib/shell";
import { log } from "../lib/log";
import { GitError, NixosBuildError } from "./errors";
import { showBanner } from "./banner";
import { checkGitConflicts, stageLocalChanges, commitChanges, pushChanges } from "./git";
import { rebuildNixos } from "./nixos";
import { showSummary } from "./summary";

const NIXOS_DIR = "/home/fractal-tess/nixos";

const program = Effect.gen(function* () {
  if (!existsSync(NIXOS_DIR)) {
    log.error(`NixOS configuration directory not found: ${NIXOS_DIR}`);
    process.exit(1);
  }

  process.chdir(NIXOS_DIR);

  if (!run(["git", "rev-parse", "--git-dir"]).ok) {
    log.error(`Not a git repository: ${NIXOS_DIR}`);
    process.exit(1);
  }

  yield* showBanner;
  yield* checkGitConflicts;
  yield* stageLocalChanges;
  yield* rebuildNixos;

  const hasStagedChanges = run(["git", "diff", "--cached", "--name-only"]).out.length > 0;

  if (hasStagedChanges) {
    const committed = yield* commitChanges;
    const pushed    = committed
      ? yield* pipe(pushChanges, Effect.map(() => true), Effect.catchAll(() => Effect.succeed(false)))
      : false;
    yield* showSummary(true, pushed);
  } else {
    log.step("No changes to commit");
    log.info("Configuration rebuilt successfully, no new commits needed");
    yield* showSummary(false, false);
  }
});

const handleError = (error: GitError | NixosBuildError) => Effect.sync(() => {
  switch (error._tag) {
    case "GitError":
      log.error(`Git operation failed: ${error.operation}`);
      if (error.detail) log.dim(`  ${error.detail}`);
      break;
    case "NixosBuildError":
      log.error("NixOS rebuild failed! Check the output above and fix the issues.");
      break;
  }
  process.exit(1);
});

Effect.runPromise(
  pipe(program, Effect.catchAll(handleError))
);
