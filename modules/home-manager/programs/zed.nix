{ pkgs, ... }: {
  # Custom zed wrapper with z.ai API configuration
  home.packages = with pkgs;
    [
      (pkgs.writeShellScriptBin "zed" ''
        export ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic"
        if [ -f "$HOME/.config/secrets/z-ai/apikey" ]; then
          export ANTHROPIC_AUTH_TOKEN="$(cat "$HOME/.config/secrets/z-ai/apikey")"
        fi
        exec ${pkgs.zed-editor}/bin/zeditor "$@"
      '')
    ];
}
