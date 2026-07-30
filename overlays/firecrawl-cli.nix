final: prev:
let
  sharedApiUrl = "http://vd.netbird.cloud:38473";
in
{
  firecrawl-cli = prev.stdenvNoCC.mkDerivation rec {
    pname = "firecrawl-cli";
    version = "1.19.27";

    src = prev.fetchFromGitHub {
      owner = "firecrawl";
      repo = "cli";
      rev = "v${version}";
      hash = "sha256-Pr0rkQ0Bl04KEnjqsLniqkCUZJPZjMfKko7Tygrp/P0=";
    };

    pnpmDeps = prev.fetchPnpmDeps {
      inherit pname version src;
      fetcherVersion = 4;
      hash = "sha256-R59OM/4zZF3+JGMG3URe60I+Vs5x9WPeQfuZjuHDodc=";
    };

    nativeBuildInputs = [
      prev.bun
      prev.nodejs_22
      prev.pnpm
      prev.pnpmConfigHook
    ];

    postPatch = ''
      substituteInPlace src/utils/config.ts \
        --replace-fail \
          "storedCredentials?.apiUrl," \
          "storedCredentials?.apiUrl || '${sharedApiUrl}',"
      substituteInPlace src/types/agent.ts \
        --replace-fail \
          $'    status: AgentStatus;\n  };\n  error?: string;\n}\n\nexport interface AgentStatusResult' \
          $'    status: AgentStatus;\n    events?: unknown[];\n    localModel?: string;\n  };\n  error?: string;\n}\n\nexport interface AgentStatusResult' \
        --replace-fail \
          $'    expiresAt?: string;\n  };' \
          $'    expiresAt?: string;\n    events?: unknown[];\n    localModel?: string;\n  };'
      substituteInPlace src/commands/agent.ts \
        --replace-fail \
          '    const { prompt, status, cancel, wait, pollInterval, timeout } = options;' \
          $'    const { prompt, status, cancel, wait, pollInterval, timeout } = options;\n    if (["<job-id>", "{job-id}", "[job-id]"].includes(prompt.trim().toLowerCase())) {\n      return { success: false, error: "Replace the job ID placeholder with an actual UUID." };\n    }' \
        --replace-warn \
          'expiresAt: status.expiresAt,' \
          $'expiresAt: status.expiresAt,\n          events: (status as unknown as { events?: unknown[] }).events,\n          localModel: (status as unknown as { localModel?: string }).localModel,' \
        --replace-warn \
          'expiresAt: agentStatus.expiresAt,' \
          $'expiresAt: agentStatus.expiresAt,\n            events: (agentStatus as unknown as { events?: unknown[] }).events,\n            localModel: (agentStatus as unknown as { localModel?: string }).localModel,' \
        --replace-warn \
          'Check status with: firecrawl agent ''${jobId}' \
          'Check status with: firecrawl agent ''${jobId} --status'
    '';

    buildPhase = ''
      runHook preBuild
      pnpm exec tsc --noEmit
      bun build src/index.ts \
        --compile \
        --target=bun-linux-x64 \
        --outfile firecrawl
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      install -Dm755 firecrawl "$out/bin/firecrawl"
      runHook postInstall
    '';

    meta = {
      description = "Firecrawl CLI configured for the shared self-hosted service";
      homepage = "https://github.com/firecrawl/cli";
      license = final.lib.licenses.isc;
      mainProgram = "firecrawl";
      platforms = [ "x86_64-linux" ];
    };
  };
}
