final: prev:
let
  version = "0.20.2";
  pinOllama =
    package:
    package.overrideAttrs (_old: {
      inherit version;
      src = prev.fetchFromGitHub {
        owner = "ollama";
        repo = "ollama";
        tag = "v${version}";
        hash = "sha256-Ic3eLOohLR7MQGkLvDJBNOCiBBKxh6l8X9MgK0b4w+Y=";
      };
      vendorHash = "sha256-Lc1Ktdqtv2VhJQssk8K1UOimeEjVNvDWePE9WkamCos=";
      postPatch = ''
        substituteInPlace version/version.go \
          --replace-fail 0.0.0 '${version}'
        rm -r app
      '';
    });
in
{
  ollama = pinOllama prev.ollama;
  ollama-cuda = pinOllama (prev.ollama.override { acceleration = "cuda"; });
}
