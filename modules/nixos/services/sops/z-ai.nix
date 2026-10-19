{
  config,
  lib,
  username,
  ...
}:

with lib;

let
  cfg = config.modules.services.sops.z_ai;
in
{
  options.modules.services.sops.z_ai = {
    enable = mkEnableOption "Z-AI secrets management via SOPS";
  };

  config = mkIf (config.modules.services.sops.enable && cfg.enable) {

    systemd.tmpfiles.rules = [
      "d /home/${username}/.config/secrets/z-ai 0755 ${username} users -"
      "d /home/${username}/.secrets.d 0755 ${username} users -"
    ];

    sops.secrets = {
      z_ai_api_key = {
        owner = username;
        sopsFile = ../../../../secrets/z-ai.json;
        format = "json";
        path = "/home/${username}/.config/secrets/z-ai/apikey";
      };
    };

    sops.templates."z-ai.fish" = {
      owner = username;
      group = username;
      mode = "0600";
      path = "/home/${username}/.secrets.d/z-ai.fish";
      content = ''
        set -gx ZAI_API_KEY "${config.sops.placeholder.z_ai_api_key}"
      '';
    };
  };
}
