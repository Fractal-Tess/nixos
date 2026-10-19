{
  config,
  lib,
  pkgs,
  username,
  ...
}:

with lib;

let
  cfg = config.modules.services.sops.dokploy;
in
{
  options.modules.services.sops.dokploy = {
    enable = mkEnableOption "Dokploy API key management via SOPS" // {
      default = true;
    };
  };

  config = mkIf (config.modules.services.sops.enable && cfg.enable) {
    systemd.tmpfiles.rules = [
      "d /home/${username}/.secrets.d 0755 ${username} users -"
    ];

    sops.secrets.dokploy_api_key = {
      owner = username;
      group = username;
      sopsFile = ../../../../secrets/dokploy-fractal-tess.json;
      format = "json";
      key = "API_KEY";
    };

    # Claude Code's Dokploy MCP server: `claude mcp add -s user dokploy -- dokploy-mcp`.
    # Reads the key at launch so it never lands in ~/.claude.json.
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "dokploy-mcp" ''
        export DOKPLOY_URL="https://dokploy.fractal-tess.xyz/api"
        DOKPLOY_API_KEY="$(cat ${config.sops.secrets.dokploy_api_key.path})"
        export DOKPLOY_API_KEY
        exec ${pkgs.nodejs}/bin/npx -y @ahdev/dokploy-mcp@1.6.0 "$@"
      '')
    ];

    sops.templates."dokploy.fish" = {
      owner = username;
      group = username;
      mode = "0600";
      path = "/home/${username}/.secrets.d/dokploy.fish";
      content = ''
        set -gx DOKPLOY_URL "https://dokploy.fractal-tess.xyz"
        set -gx DOKPLOY_API_KEY "${config.sops.placeholder.dokploy_api_key}"
      '';
    };
  };
}
