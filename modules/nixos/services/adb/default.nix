{ config, lib, pkgs, ... }:

with lib;

let cfg = config.modules.services.adb;
in {
  options.modules.services.adb = {
    enable = mkEnableOption "Android Debug Bridge";
  };

  config = mkIf cfg.enable {
    programs.adb.enable = true;
    services.udev.packages = with pkgs; [ android-udev-rules ];
  };
}
