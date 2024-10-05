{ inputs, config, lib, pkgs, username, ... }:
with lib;
let
  cfg = config.modules.display.hyprland;
in
{
  options.modules.display.hyprland = {
    enable = mkEnableOption "Hyprland";

    xdgPortal = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable communication between windows.";
      };
      extraPortals = mkOption {
        type = types.listOf types.package;
        default = [ pkgs.xdg-desktop-portal-gtk ];
        description = "Extra portals to install for communication between windows.";
      };
    };
    videoDrivers = mkOption {
      type = types.listOf types.str;
      # If using nvidia, add [ "nvidia" ] to the list
      default = [ ];
      description = "The video drivers to load for Xorg and Wayland.";
    };
    greetd = {
      enable = mkEnableOption "Greetd";
      autoLogin = mkOption {
        type = types.bool;
        default = false;
        description = "Automatically login the user.";
      };
    };
    openGL = {
      enable = mkEnableOption "OpenGL";
      extraPackages = mkOption {
        type = types.listOf types.package;
        default = [ pkgs.libvdpau-va-gl ];
        description = "Extra packages to install for OpenGL.";
      };
      extraPackages32 = mkOption {
        type = types.listOf types.package;
        default = [ ];
        description = "Extra packages to install for 32-bit OpenGL.";
      };
    };

  };
  config = mkIf cfg.enable {
    # Hyprland
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    };

    # Communication between windows
    xdg.portal = mkIf cfg.xdgPortal.enable {
      enable = true;
      extraPortals = cfg.xdgPortal.extraPortals;
    };

    # Greetd
    services.greetd = mkIf cfg.greetd.enable {
      enable = true;
      settings = {
        initial_session = mkIf cfg.greetd.autoLogin {
          command = "${pkgs.hyprland}/bin/Hyprland";
          user = username;
        };
        default_session = {
          command = "${pkgs.greetd.tuigreet}/bin/tuigreet --greeting 'Welcome, ${username}!' --asterisks --remember --remember-user-session --time -cmd ${pkgs.hyprland}/bin/Hyprland";
          user = username;
        };
      };
    };

    # Gpu drivers (if any)
    services.xserver.videoDrivers = cfg.videoDrivers;

    # Enable OpenGL
    hardware.graphics = mkIf cfg.openGL.enable {
      enable = true;
      enable32Bit = true;
      extraPackages = cfg.openGL.extraPackages;
      extraPackages32 = cfg.openGL.extraPackages32;
    };
  };
}
