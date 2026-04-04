final: prev:
let
  version = "0.20.2";
  ollamaBase = prev.ollama.overrideAttrs (_old: {
    inherit version;
    src = prev.fetchFromGitHub {
      owner = "ollama";
      repo = "ollama";
      tag = "v${version}";
      hash = "sha256-Ic3eLOohLR7MQGkLvDJBNOCiBBKxh6l8X9MgK0b4w+Y=";
    };
    vendorHash = "sha256-Lc1Ktdqtv2VhJQssk8K1UOimeEjVNvDWePE9WkamCos=";
  });
in
{
  ollama = ollamaBase;
  ollama-cuda = ollamaBase.override { acceleration = "cuda"; };
}
