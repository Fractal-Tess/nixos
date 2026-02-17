import { Data } from "effect";

export class GitError extends Data.TaggedError("GitError")<{
  readonly operation: string;
  readonly detail?: string;
}> {}

export class NixosBuildError extends Data.TaggedError("NixosBuildError")<{}> {}
