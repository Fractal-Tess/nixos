import { Effect } from "effect";
import { Data } from "effect";
import { run, runLive } from "./shell";

export class ShellError extends Data.TaggedError("ShellError")<{
  readonly cmd: string;
  readonly detail?: string;
}> {}

/** Run a command and return its output, failing with ShellError if non-zero. */
export const exec = (cmd: string[]): Effect.Effect<string, ShellError> =>
  Effect.sync(() => run(cmd)).pipe(
    Effect.flatMap(({ out, ok }) =>
      ok
        ? Effect.succeed(out)
        : Effect.fail(new ShellError({ cmd: cmd.join(" ") }))
    )
  );

/** Run a command and return its output, returning null on failure instead of failing. */
export const capture = (cmd: string[]): Effect.Effect<string | null, never> =>
  Effect.sync(() => {
    const { out, ok } = run(cmd);
    return ok ? out : null;
  });

/** Run a command with inherited stdio (live output), failing with ShellError if non-zero. */
export const execLive = (cmd: string[]): Effect.Effect<void, ShellError> =>
  Effect.promise(() => runLive(cmd)).pipe(
    Effect.flatMap(ok =>
      ok
        ? Effect.void
        : Effect.fail(new ShellError({ cmd: cmd.join(" ") }))
    )
  );
