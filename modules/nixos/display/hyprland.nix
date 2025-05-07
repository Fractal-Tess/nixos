{ inputs, config, lib, pkgs, ... }:

with lib;

let cfg = config.modules.display.hyprland;
in {
  # Option to enable or disable Hyprland
  options.modules.display.hyprland.enable = mkEnableOption "Hyprland";

  config = mkIf cfg.enable {
    # Enable Hyprland compositor
    programs.hyprland = {
      enable = true;
      # Enable X11 compatibility for legacy apps
      xwayland.enable = true;
      # Enable UWSM
      withUWSM = true;
    };

    programs.hyprlock.enable = true;

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
    # Add nvidia driver for Xorg and Wayland if nvidia is enabled
    services.xserver.videoDrivers = mkMerge [
      (mkIf config.modules.drivers.nvidia.enable (mkDefault [ "nvidia" ]))
      (mkIf config.modules.drivers.amd.enable (mkDefault [ "amdgpu" ]))
    ];
  };
}
