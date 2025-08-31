{ lib, buildNpmPackage, fetchzip, nodejs_20, }:

buildNpmPackage rec {
  pname = "claude-flow";
  version = "2.0.0-alpha.101";

  nodejs = nodejs_20; # required for sandboxed Nix builds on Darwin

  src = fetchzip {
    url = "https://registry.npmjs.org/claude-flow/-/claude-flow-${version}.tgz";
    hash = "sha256-TsmailSJ7iwbF5BbXHNVXALSuulNaNOX6MqGVasRKb8=";
  };

  npmDepsHash = "sha256-Owip6wXFl1yKKpmwlEbrzC/caIzqoqhhWnKahB2dTwY=";

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  dontNpmBuild = true;

  # Skip puppeteer download during build
  PUPPETEER_SKIP_DOWNLOAD = "1";

  meta = {
    description =
      "Enterprise-grade AI agent orchestration with ruv-swarm integration (Alpha Release)";
    homepage = "https://github.com/ruvnet/claude-code-flow";
    downloadPage =
      "https://www.npmjs.com/package/claude-flow/v/2.0.0-alpha.101";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ fractal-tess ];
    mainProgram = "claude-flow";
  };
}

