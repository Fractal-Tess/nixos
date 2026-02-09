{
  config,
  lib,
  username,
  ...
}:

with lib;

let
  cfg = config.modules.services.sops.syncthing;
in
{
  options.modules.services.sops.syncthing = {
    enable = mkEnableOption "Syncthing secrets management via SOPS";
  };

  config = mkIf (config.modules.services.sops.enable && cfg.enable) {

    systemd.tmpfiles.rules = [
      "d /home/${username}/.config/secrets/syncthing 0755 ${username} users -"
    ];

    sops.secrets = {
      syncthing_user = {
        owner = username;
        sopsFile = ../../../../secrets/syncthing.json;
        format = "json";
        key = "user";
        path = "/home/${username}/.config/secrets/syncthing/user";
      };
      syncthing_pass = {
        owner = username;
        sopsFile = ../../../../secrets/syncthing.json;
        format = "json";
        key = "pass";
        path = "/home/${username}/.config/secrets/syncthing/pass";
      };
    };
  };
}
