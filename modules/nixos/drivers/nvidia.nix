{ config, lib, ... }:

with lib;

let cfg = config.modules.hardware.nvidia;
in {
  options.modules.hardware.nvidia = {
    # Enable or disable the NVIDIA configuration module.
    enable = mkEnableOption "NVIDIA configuration";

    powerManagement = {
      # Enable or disable NVIDIA power management (experimental).
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable NVIDIA power management (experimental)";
      };

      # Enable or disable fine-grained power management for modern NVIDIA GPUs.
      finegrained = mkOption {
        type = types.bool;
        default = false;
        description =
          "Enable fine-grained power management for modern NVIDIA GPUs (turing and after)";
      };
    };

    # Use the NVIDIA open source kernel module.
    open = mkOption {
      type = types.bool;
      default = false;
      description = "Use the NVIDIA open source kernel module";
    };

    # Enable or disable the NVIDIA settings menu.
    nvidiaSettings = mkOption {
      type = types.bool;
      default = true;
      description = "Enable the NVIDIA settings menu";
    };

    # Select the NVIDIA driver package to use.
    package = mkOption {
      type = types.enum [ "stable" "beta" "production" "vulkan_beta" ];
      default = "stable";
      description =
        "NVIDIA driver package to use: stable, beta, production, or vulkan_beta";
    };
  };

  config = mkIf cfg.enable {
    # Add nvidia driver for Xorg and Wayland
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.nvidia = {
      # Modesetting is required.
      modesetting.enable = mkDefault true;

      # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
      # Enable this if you have graphical corruption issues or application crashes after waking
      # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead 
      # of just the bare essentials.
      powerManagement = {
        enable = cfg.powerManagement.enable;
        # Fine-grained power management. Turns off GPU when not in use.
        # Experimental and only works on modern Nvidia GPUs (Turing or newer).
        finegrained = cfg.powerManagement.finegrained;
      };

      # Use the NVidia open source kernel module (not to be confused with the
      # independent third-party "nouveau" open source driver).
      # Support is limited to the Turing and later architectures. Full list of 
      # supported GPUs is at: 
      # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
      # Only available from driver 515.43.04+
      open = cfg.open;

      # Enable the Nvidia settings menu,
      # accessible via `nvidia-settings`
      nvidiaSettings = cfg.nvidiaSettings;

      # Optionally, you may need to select the appropriate driver version for your specific GPU.
      package = config.boot.kernelPackages.nvidiaPackages.${cfg.package};
    };
  };
}
