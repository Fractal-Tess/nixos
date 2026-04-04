final: prev: {
  # Provide a lightweight wrapper instead of building the CUDA stack in Nix.
  # The actual vLLM package is resolved and cached by uv at runtime.
  vllm = prev.writeShellScriptBin "vllm" ''
    set -euo pipefail

    export LD_LIBRARY_PATH="/run/opengl-driver/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

    exec ${prev.uv}/bin/uv tool run --from "vllm==0.16.0" vllm "$@"
  '';
}
