final: prev: {
  zed-editor = prev.runCommand "zed-editor-wrapped" { } ''
    mkdir -p $out/bin

    cat > $out/bin/zed <<'EOF'
    #!${prev.bash}/bin/bash
    export ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic"
    if [ -f "$HOME/.config/secrets/z-ai.apikey" ]; then
      export ANTHROPIC_AUTH_TOKEN="$(cat "$HOME/.config/secrets/z-ai.apikey")"
    fi
    exec ${prev.zed-editor}/bin/zed "$@"
    EOF

    chmod +x $out/bin/zed
  '';
}