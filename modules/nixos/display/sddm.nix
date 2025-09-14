{ config, lib, pkgs, username, ... }:

with lib;

let
  cfg = config.modules.display.sddm;
  hyprland = config.modules.display.hyprland;

in
{
  options.modules.display.sddm = {
    # Option to enable/disable SDDM display manager
    enable = mkEnableOption "SDDM display manager";
    
    # Option to enable the astronaut theme
    enableAstronautTheme = mkEnableOption "SDDM Astronaut theme" // { default = true; };
  };

  # Configuration that applies when this module is enabled
  config = mkIf cfg.enable {
    # Check if Hyprland is enabled, otherwise throw an error
    assertions = [{
      assertion = hyprland.enable;
      message =
        "SDDM is configured to use Hyprland, but Hyprland is not enabled. Please enable modules.display.hyprland.";
    }];

    # Install SDDM astronaut theme package
    environment.systemPackages = mkIf cfg.enableAstronautTheme [
      pkgs.sddm-astronaut
    ];

    # Enable SDDM display manager
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      theme = mkIf cfg.enableAstronautTheme "sddm-astronaut-theme";
      # Configuration for the black hole variant
      settings = mkIf cfg.enableAstronautTheme {
        Theme = {
          ConfigFile = "Themes/blackhole.conf";
        };
      };
    };

    # Use Hyprland UWSM session (as shown in error message)
    services.displayManager.defaultSession = "hyprland-uwsm";
  };
}