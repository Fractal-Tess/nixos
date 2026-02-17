export function run(cmd: string[]): { out: string; ok: boolean } {
  const r = Bun.spawnSync(cmd, { stdout: "pipe", stderr: "pipe" });
  return { out: new TextDecoder().decode(r.stdout).trim(), ok: r.exitCode === 0 };
}

export async function runLive(cmd: string[]): Promise<boolean> {
  const p = Bun.spawn(cmd, { stdin: "inherit", stdout: "inherit", stderr: "inherit" });
  return (await p.exited) === 0;
}
