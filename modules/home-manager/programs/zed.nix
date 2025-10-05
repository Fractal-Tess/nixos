{ pkgs, ... }: {
  home.packages = [
    (pkgs.symlinkJoin {
      name = "zed-editor-wrapped";
      paths = [ pkgs.zed-editor ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/zed \
          --set ANTHROPIC_BASE_URL "https://api.z.ai/api/anthropic" \
          --run 'if [ -f "$HOME/.config/secrets/z-ai.apikey" ]; then export ANTHROPIC_AUTH_TOKEN="$(cat "$HOME/.config/secrets/z-ai.apikey")"; fi'
      '';
    })
  ];
}