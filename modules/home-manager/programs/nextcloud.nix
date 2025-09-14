{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.programs.nextcloud;
in
{
  options.modules.programs.nextcloud = {
    enable = mkEnableOption "Nextcloud client";
  };

  config = mkIf cfg.enable {
    services.nextcloud-client = {
      enable = true;
      startInBackground = true;
    };
  };
}
