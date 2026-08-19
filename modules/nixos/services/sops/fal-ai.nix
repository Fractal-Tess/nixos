{
  config,
  lib,
  username,
  ...
}:

with lib;

let
  cfg = config.modules.services.sops.fal_ai;
in
{
  options.modules.services.sops.fal_ai = {
    enable = mkEnableOption "FAL AI secrets management via SOPS";
  };

  config = mkIf (config.modules.services.sops.enable && cfg.enable) {
    systemd.tmpfiles.rules = [
      "d /home/${username}/.secrets.d 0755 ${username} users -"
    ];

    sops.secrets.fal_ai_api_key = {
      owner = username;
      group = username;
      sopsFile = ../../../../secrets/fal-ai.json;
      format = "json";
    };

    sops.templates."fal-ai.fish" = {
      owner = username;
      group = username;
      mode = "0600";
      path = "/home/${username}/.secrets.d/fal-ai.fish";
      content = ''
        set -gx FAL_AI "${config.sops.placeholder.fal_ai_api_key}"
      '';
    };
  };
}
