{ config, lib, ... }:

with lib;

{
  config = mkIf config.modules.drivers.nvidia {
    # Add nvidia driver for Xorg and Wayland
    services.xserver.videoDrivers = mkIf config.modules.gui [ "nvidia" ];

    hardware.nvidia = {
      # Modesetting is required.
      modesetting.enable = mkDefault true;

      # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
      # Enable this if you have graphical corruption issues or application crashes after waking
      # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead 
      # of just the bare essentials.
      powerManagement = {
        enable = false; # Default value
        # Fine-grained power management. Turns off GPU when not in use.
        # Experimental and only works on modern Nvidia GPUs (Turing or newer).
        finegrained = false; # Default value
      };

      # Use the NVidia open source kernel module (not to be confused with the
      # independent third-party "nouveau" open source driver).
      # Support is limited to the Turing and later architectures. Full list of 
      # supported GPUs is at: 
      # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
      # Only available from driver 515.43.04+
      open = false; # Default value

      # Enable the Nvidia settings menu,
      # accessible via `nvidia-settings`
      nvidiaSettings = true; # Default value

      # Optionally, you may need to select the appropriate driver version for your specific GPU.
      package =
        config.boot.kernelPackages.nvidiaPackages.stable; # Default value
    };
  };
}
