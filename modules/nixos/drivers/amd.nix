{ config, lib, ... }:

with lib;

let cfg = config.modules.drivers.amd;

in {
  options.modules.drivers.amd = { enable = mkEnableOption "AMD GPU drivers"; };

  config = mkIf cfg.enable {
    # Add AMD driver for Xorg and Wayland
    services.xserver.videoDrivers = mkDefault [ "amdgpu" ];
    # Enable early KMS for better ret
    boot.initrd.kernelModules = [ "amdgpu" ];
    # Enable firmware for AMD GPUs
    hardware.enableRedistributableFirmware = mkDefault true;
  };
}
