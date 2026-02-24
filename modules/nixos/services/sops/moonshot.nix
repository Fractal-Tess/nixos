{
  config,
  lib,
  username,
  ...
}:

with lib;

let
  cfg = config.modules.services.sops.moonshot;
in
{
  options.modules.services.sops.moonshot = {
    enable = mkEnableOption "Moonshot AI (Kimi) secrets management via SOPS";
  };

  config = mkIf (config.modules.services.sops.enable && cfg.enable) {

    systemd.tmpfiles.rules = [
      "d /home/${username}/.config/secrets/moonshot_ai 0755 ${username} users -"
    ];

    sops.secrets = {
      moonshot_ai = {
        owner = username;
        sopsFile = ../../../../secrets/secrets.json;
        format = "json";
        path = "/home/${username}/.config/secrets/moonshot_ai";
      };
    };
  };
}
