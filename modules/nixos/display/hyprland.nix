{ config, lib, pkgs, username, ... }:

with lib;
let cfg = config.modules.display.hyprland;
in {
  # Options for Hyprland configuration
  options.modules.display.hyprland = {
    enable = mkEnableOption "Hyprland";
  };

  config = mkIf cfg.enable {
    # Enable Hyprland compositor
    programs.hyprland = {
      enable = true;
      portalPackage = pkgs.xdg-desktop-portal-hyprland;

      # Enable Xwayland
      xwayland.enable = true;
      # Enable UWSM
      withUWSM = true;
    };

    # Hardware acceleration
    # hardware.graphics = {
    #   enable = true;
    #   # 32-bit support
    #   enable32Bit = true;
    # };

    # Enable Hyprlock
    programs.hyprlock.enable = true;
    # Enable Hypridle
    services.hypridle.enable = true;

    # Enable XDG Desktop Portal for sandboxed/Wayland apps
    xdg.portal = {
      enable = mkDefault true;
      #   # Use portal for xdg-open
      xdgOpenUsePortal = mkDefault true;
      #   # Add GTK portal backend
      extraPortals = mkDefault [ pkgs.xdg-desktop-portal-gtk ];
    };

    # Add ghostty terminal to system packages
    environment.systemPackages = [ pkgs.ghostty ];
    # Enable dconf for GTK/Flatpak app settings
    # programs.dconf.enable = true;

    # Add nvidia driver for
    services.xserver.videoDrivers = mkMerge [
      (mkIf config.modules.drivers.nvidia.enable [ "nvidia" ])
      (mkIf config.modules.drivers.amd.enable [ "amdgpu" ])
    ];
  };
}
