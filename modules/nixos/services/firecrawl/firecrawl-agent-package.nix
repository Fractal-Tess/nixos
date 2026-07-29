{ pkgs, serverSource }:

let
  version = "0.1.0-f023adf";
  source = pkgs.fetchFromGitHub {
    owner = "firecrawl";
    repo = "web-agent";
    rev = "f023adf1cd1f731e27fdc844af62996f6c2a41c4";
    hash = "sha256-t/sbYxzFfH61dJBm1jhGa0UaHxE/qrPPQ5IChw3O0S8=";
  };
  expressSource =
    pkgs.runCommand "firecrawl-web-agent-express-source" { nativeBuildInputs = [ pkgs.jq ]; }
      ''
        cp -r ${source}/agent-templates/express "$out"
        chmod -R u+w "$out"
        jq \
          '.dependencies.papaparse = "^5.4.1" | .devDependencies["@types/papaparse"] = "^5.3.15"' \
          "$out/package.json" > "$out/package.json.new"
        mv "$out/package.json.new" "$out/package.json"
      '';
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "firecrawl-web-agent";
  inherit version;
  src = expressSource;

  pnpmDeps = pkgs.fetchPnpmDeps {
    pname = "firecrawl-web-agent";
    inherit version;
    src = expressSource;
    fetcherVersion = 4;
    hash = "sha256-DlXDfuxihrBjqzxbHmxPtGxZQpDfr3TJN135rdnvzHM=";
  };

  nativeBuildInputs = [
    pkgs.nodejs_22
    pkgs.pnpm
    pkgs.pnpmConfigHook
  ];

  postPatch = ''
    cp ${serverSource} server.ts
    substituteInPlace agent-core/src/types.ts \
      --replace-fail \
        'export interface FirecrawlToolsConfig {' \
        $'export interface FirecrawlToolsConfig {\n  /** Self-hosted Firecrawl API base URL. */\n  apiUrl?: string;'
    substituteInPlace agent-core/src/agent.ts \
      --replace-fail \
        '{ configurable: { runState } },' \
        '{ recursionLimit: (params.maxSteps ?? this.options.maxSteps ?? 50) * 2 + 1, configurable: { runState } },' \
      --replace-fail \
        '{ streamMode: ["messages", "updates"], configurable: { runState } },' \
        '{ streamMode: ["messages", "updates"], recursionLimit: (params.maxSteps ?? this.options.maxSteps ?? 50) * 2 + 1, configurable: { runState } },'
  '';

  buildPhase = ''
    runHook preBuild
    node_modules/.pnpm/node_modules/.bin/esbuild server.ts \
      --bundle \
      --platform=node \
      --format=esm \
      --packages=external \
      --outfile=server.mjs
    node --check server.mjs
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/app"
    cp -r agent-core package.json pnpm-lock.yaml server.mjs "$out/app/"
    cp -a node_modules "$out/app/"
    runHook postInstall
  '';

  meta = {
    description = "Pinned local Firecrawl autonomous web-agent service";
    homepage = "https://github.com/firecrawl/web-agent";
    license = pkgs.lib.licenses.mit;
    platforms = pkgs.lib.platforms.linux;
  };
}
