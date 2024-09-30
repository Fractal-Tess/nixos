{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.services.filesystemExtraServices;
in
{
  options.modules.services.filesystemExtraServices = {
    enable = mkEnableOption "Filesystem utilities";
  };

  config = mkIf cfg.enable {
    # Filesystem utilities
    services.udisks2.enable = true;
    services.devmon.enable = true;
    services.udev.packages = [ pkgs.android-udev-rules ];
    services.gvfs.enable = true;
  };
}
