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
      license = final.lib.licenses.mit;
      mainProgram = "firecrawl";
      platforms = [ "x86_64-linux" ];
    };
  };
}
