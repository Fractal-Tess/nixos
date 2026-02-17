import { Effect } from "effect";
import { run } from "../lib/shell";
import { c, log } from "../lib/log";
import { GitError } from "./errors";
import { generateCommitMessage } from "./ai";

export const checkGitConflicts = Effect.gen(function* () {
  log.step("Checking for remote changes...");

  const fetched = run(["git", "fetch", "origin"]);
  if (!fetched.ok) {
    yield* Effect.fail(new GitError({ operation: "fetch", detail: "Check your network connection" }));
  }

  const branch = run(["git", "branch", "--show-current"]).out;
  const behind = parseInt(run(["git", "rev-list", "--count", `HEAD..origin/${branch}`]).out || "0");

  if (behind === 0) {
    log.success("Already up to date with remote");
    return;
  }

  log.info(`Remote has ${behind} new commit(s)`);
  const dirty = run(["git", "status", "--porcelain"]).out.length > 0;

  if (dirty) {
    log.warning("You have local uncommitted changes");
    log.info("Stashing local changes...");

    const stashed = run(["git", "stash", "push", "-m", `update-script-autostash-${Date.now()}`]);
    if (!stashed.ok) {
      yield* Effect.fail(new GitError({
        operation: "stash",
        detail: "Please commit or stash your changes manually before running this script",
      }));
    }

    const pulled = run(["git", "pull", "--rebase", "origin", branch]);
    if (pulled.ok) {
      log.success("Pulled remote changes successfully");
      const popped = run(["git", "stash", "pop"]);
      if (!popped.ok) {
        yield* Effect.fail(new GitError({
          operation: "stash-pop",
          detail: "Conflict restoring local changes. Run: git stash show -p, resolve, then git stash drop",
        }));
      }
      log.success("Restored local changes");
    } else {
      run(["git", "stash", "pop"]);
      yield* Effect.fail(new GitError({
        operation: "pull",
        detail: `Conflicts detected. Resolve manually: git rebase origin/${branch}`,
      }));
    }
  } else {
    const pulled = run(["git", "pull", "--rebase", "origin", branch]);
    if (!pulled.ok) {
      yield* Effect.fail(new GitError({ operation: "pull", detail: "Please resolve manually and run again" }));
    }
    log.success(`Pulled ${behind} commit(s) from remote`);
  }
});

export const stageLocalChanges = Effect.sync(() => {
  log.step("Staging local changes...");

  const status = run(["git", "status", "--porcelain"]).out;
  if (!status) {
    log.info("No local changes to stage");
    return;
  }

  log.info("Files to be staged:");
  for (const line of status.split("\n").filter(Boolean)) {
    const st   = line.substring(0, 2);
    const file = line.substring(3);
    if (st === "??")                        console.log(`  ${c.green}+ (new)${c.reset}      ${file}`);
    else if ([" M","M ","MM"].includes(st)) console.log(`  ${c.yellow}~ (modified)${c.reset} ${file}`);
    else if ([" D","D "].includes(st))      console.log(`  ${c.red}- (deleted)${c.reset}  ${file}`);
    else                                    console.log(`  ${c.blue}? (${st})${c.reset}    ${file}`);
  }
  console.log();

  run(["git", "add", "-A"]);
  log.success("All changes staged");
});

export const commitChanges = Effect.gen(function* () {
  log.step("Committing changes...");

  if (!run(["git", "diff", "--cached", "--name-only"]).out) {
    log.info("No staged changes to commit");
    return false;
  }

  log.info("Generating commit message via AI...");
  const msg = yield* generateCommitMessage;

  const committed = run(["git", "commit", "-m", msg]);
  if (!committed.ok) {
    yield* Effect.fail(new GitError({ operation: "commit" }));
  }

  log.success(`Committed: ${msg}`);
  return true;
});

export const pushChanges = Effect.gen(function* () {
  log.step("Pushing to remote...");
  const branch = run(["git", "branch", "--show-current"]).out;

  const pushed = run(["git", "push", "origin", branch]);
  if (!pushed.ok) {
    yield* Effect.fail(new GitError({
      operation: "push",
      detail: `You may need to push manually: git push origin ${branch}`,
    }));
  }

  log.success(`Pushed to origin/${branch}`);
});
