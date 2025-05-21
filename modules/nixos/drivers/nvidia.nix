{ config, lib, ... }:

with lib;

let cfg = config.modules.drivers.nvidia;

in {
  options.modules.drivers.nvidia = {
    enable = mkEnableOption "NVIDIA GPU drivers";
  };

  config = mkIf cfg.enable {

    hardware.nvidia = {

      # Modesetting is required.
      modesetting.enable = mkDefault true;

      # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
      # Enable this if you have graphical corruption issues or application crashes after waking
      # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead 
      # of just the bare essentials.
      powerManagement = {
        enable = mkDefault false;
        # Fine-grained power management. Turns off GPU when not in use.
        # Experimental and only works on modern Nvidia GPUs (Turing or newer).
        finegrained = mkDefault false;
      };

      # Use the NVidia open source kernel module (not to be confused with the
      # independent third-party "nouveau" open source driver).
      # Support is limited to the Turing and later architectures. Full list of 
      # supported GPUs is at: 
      # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
      # Only available from driver 515.43.04+
      open = mkDefault false;

      # Enable the Nvidia settings menu,
      # accessible via `nvidia-settings`
      nvidiaSettings = mkDefault true;

      # Optionally, you may need to select the appropriate driver version for your specific GPU.
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };
}
