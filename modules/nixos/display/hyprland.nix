{ config, lib, pkgs, username, ... }:

with lib;
let cfg = config.modules.display.hyprland;
in {
  # Option to enable or disable Hyprland
  options.modules.display.hyprland.enable = mkEnableOption "Hyprland";

  config = mkIf cfg.enable {
    # Enable Hyprland compositor
    programs.hyprland = {
      enable = true;

      package = pkgs.hyprland;
      portalPackage = pkgs.xdg-desktop-portal-hyprland;

      # Enable Xwayland
      xwayland.enable = true;
      # Enable UWSM
      withUWSM = true;
    };
    services.getty.autologinUser = username;

    hardware.graphics = {
      # if you also want 32-bit support (e.g for Steam)
      enable32Bit = true;
      package32 = pkgs.pkgsi686Linux.mesa;
    };

    # Enable Hyprlock
    programs.hyprlock.enable = true;
    # Enable Hypridle
    services.hypridle.enable = true;

    # Enable XDG Desktop Portal for sandboxed/Wayland apps
    xdg.portal = {
      enable = mkDefault true;
      # Use portal for xdg-open
      xdgOpenUsePortal = mkDefault true;
      # Add GTK portal backend
      extraPortals = mkDefault [ pkgs.xdg-desktop-portal-gtk ];
    };

    # Add kitty terminal to system packages
    environment.systemPackages = [ pkgs.kitty ];
    # Enable dconf for GTK/Flatpak app settings
    programs.dconf.enable = true;
    # Add nvidia driver for
    services.xserver.videoDrivers = mkMerge [
      (mkIf config.modules.drivers.nvidia.enable [ "nvidia" ])
      (mkIf config.modules.drivers.amd.enable [ "amdgpu" ])
    ];
  };
}
