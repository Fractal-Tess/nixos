{ config, lib, ... }:

with lib;

let cfg = config.modules.drivers.amd;
in {
  options.modules.drivers.amd = { enable = mkEnableOption "AMD GPU drivers"; };

  config = mkIf cfg.enable {
    # Add AMD driver for Xorg and Wayland
    services.xserver.videoDrivers = mkDefault [ "amdgpu" ];

    hardware.opengl = {
      # Enable OpenGL support
      enable = mkDefault true;
      # Enable 32-bit support for OpenGL (needed for some applications)
      driSupport32Bit = mkDefault true;
      # Add extra packages for AMD GPU support
      extraPackages = with pkgs; [ amdvlk rocm-opencl-icd rocm-opencl-runtime ];
      # Add 32-bit versions of the packages
      extraPackages32 = with pkgs.driversi686Linux; [ amdvlk ];
    };

    # Enable early KMS for better resolution during boot
    boot.initrd.kernelModules = [ "amdgpu" ];

    # Enable firmware for AMD GPUs
    hardware.enableRedistributableFirmware = mkDefault true;
  };
}
