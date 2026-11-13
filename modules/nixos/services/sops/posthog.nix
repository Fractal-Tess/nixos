{
  config,
  lib,
  pkgs,
  username,
  ...
}:

with lib;

let
  cfg = config.modules.services.sops.posthog;
in
{
  options.modules.services.sops.posthog = {
    enable = mkEnableOption "PostHog personal API key management via SOPS" // {
      default = true;
    };
  };

  config = mkIf (config.modules.services.sops.enable && cfg.enable) {
    systemd.tmpfiles.rules = [
      "d /home/${username}/.secrets.d 0755 ${username} users -"
    ];

    # Read-only personal API key for the CarrierX PostHog project (id 391530).
    sops.secrets.posthog_api_key = {
      owner = username;
      group = username;
      sopsFile = ../../../../secrets/posthog.json;
      format = "json";
      key = "API_KEY";
    };

    # Claude Code's PostHog MCP server: `claude mcp add -s user posthog -- posthog-mcp`.
    # Reads the key at launch so it never lands in ~/.claude.json.
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "posthog-mcp" ''
        POSTHOG_API_KEY="$(cat ${config.sops.secrets.posthog_api_key.path})"
        exec ${pkgs.nodejs}/bin/npx -y mcp-remote@0.16.6 https://mcp.posthog.com/mcp \
          --header "Authorization:Bearer $POSTHOG_API_KEY" "$@"
      '')
    ];

    sops.templates."posthog.fish" = {
      owner = username;
      group = username;
      mode = "0600";
      path = "/home/${username}/.secrets.d/posthog.fish";
      content = ''
        set -gx POSTHOG_HOST "https://us.posthog.com"
        set -gx POSTHOG_PROJECT_ID "391530"
        set -gx POSTHOG_PERSONAL_API_KEY "${config.sops.placeholder.posthog_api_key}"
      '';
    };
  };
}
