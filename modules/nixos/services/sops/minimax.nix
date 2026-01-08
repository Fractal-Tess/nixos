{ config, lib, username, ... }:

with lib;

let cfg = config.modules.services.sops.minimax;
in {
  options.modules.services.sops.minimax = {
    enable = mkEnableOption "Minimax secrets management via SOPS";
  };

  config = mkIf (config.modules.services.sops.enable && cfg.enable) {

    systemd.tmpfiles.rules =
      [ "d /home/${username}/.config/secrets/minimax 0755 ${username} users -" ];

    sops.secrets = {
      api_key = {
        owner = username;
        sopsFile = ../../../../secrets/minimax.yaml;
        format = "yaml";
        path = "/home/${username}/.config/secrets/minimax/apikey";
      };
    };
  };
}
