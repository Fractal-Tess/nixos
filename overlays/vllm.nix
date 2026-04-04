final: prev: {
  # Provide a lightweight wrapper instead of building the CUDA stack in Nix.
  # The actual vLLM package is resolved and cached by uv at runtime.
  vllm = prev.writeShellScriptBin "vllm" ''
    set -euo pipefail

    exec ${prev.uv}/bin/uv tool run --from "vllm==0.16.0" vllm "$@"
  '';
}
