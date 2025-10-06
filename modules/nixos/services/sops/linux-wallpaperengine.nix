{ config, lib, username, ... }:

with lib;

let cfg = config.modules.services.sops.linux_wallpaperengine;
in {
  options.modules.services.sops.linux_wallpaperengine = {
    enable =
      mkEnableOption "Linux wallpaper engine secrets management via SOPS";
  };

  config = mkIf (config.modules.services.sops.enable && cfg.enable) {

    systemd.tmpfiles.rules = [
      "d /home/${username}/.config/secrets/linux-wallpaperengine 0755 ${username} users -"
    ];

    sops.secrets = {
      "HDMI_A_1" = {
        owner = username;
        sopsFile = ../../../../secrets/linux-wallpaperengine.json;
        format = "json";
        path =
          "/home/${username}/.config/secrets/linux-wallpaperengine/HDMI_A_1";
      };

      "DP-3" = {
        owner = username;
        sopsFile = ../../../../secrets/linux-wallpaperengine.json;
        format = "json";
        path = "/home/${username}/.config/secrets/linux-wallpaperengine/DP-3";
      };

      "ANY" = {
        owner = username;
        sopsFile = ../../../../secrets/linux-wallpaperengine.json;
        format = "json";
        path = "/home/${username}/.config/secrets/linux-wallpaperengine/ANY";
      };
    };
  };
}
