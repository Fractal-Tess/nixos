{ config, lib, pkgs, ... }:

with lib;

let cfg = config.modules.services.virtualization.firecracker;
in {
  options.modules.services.virtualization.firecracker = {
    enable = mkEnableOption "Firecracker support";
  };

  config = mkIf cfg.enable {
    # Install Firecracker and related tools
    environment.systemPackages = with pkgs; [ firecracker firectl ];
  };
}
