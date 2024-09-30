{ config, lib, username, ... }:

with lib;

let
  cfg = config.modules.services.docker;
in
{
  options.modules.services.docker = {
    enable = mkEnableOption "Docker";
    rootless = mkEnableOption "Rootless Docker";
    nvidia = mkEnableOption "Nvidia support";
  };

  config = mkIf cfg.enable {
    users.extraGroups.docker.members = [ username ];

    # GPU Drivers  (Nvidia) for containers
    hardware.nvidia-container-toolkit.enable = cfg.nvidia;

    virtualisation.docker = {
      enable = true;
      rootless = mkIf cfg.rootless {
        enable = true;
        setSocketVariable = true;
      };
    };
  };
}