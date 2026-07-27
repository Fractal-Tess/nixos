final: prev: {
  firecrawl-cli = prev.stdenvNoCC.mkDerivation rec {
    pname = "firecrawl-cli";
    version = "1.19.27";

    src = prev.fetchurl {
      url = "https://github.com/firecrawl/cli/releases/download/v${version}/firecrawl-linux-x64.tar.gz";
      hash = "sha256-cQxhF2mTogtfjALKnqWlnNYqhc4xqFgKl7oXkUsxC9Q=";
    };

    sourceRoot = ".";
    dontStrip = true; # Stripping removes Bun's embedded Firecrawl program.
    nativeBuildInputs = [ prev.autoPatchelfHook ];
    buildInputs = [ prev.stdenv.cc.cc.lib ];

    installPhase = ''
      runHook preInstall
      install -Dm755 firecrawl-linux-x64 "$out/bin/firecrawl"
      runHook postInstall
    '';

    meta = {
      description = "CLI and agent skill for Firecrawl";
      homepage = "https://github.com/firecrawl/cli";
      license = final.lib.licenses.mit;
      mainProgram = "firecrawl";
      platforms = [ "x86_64-linux" ];
    };
  };
}
