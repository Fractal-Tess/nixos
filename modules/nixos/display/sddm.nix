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
  };

  # Configuration that applies when this module is enabled
  config = mkIf cfg.enable {
    # Check if Hyprland is enabled, otherwise throw an error
    assertions = [{
      assertion = hyprland.enable;
      message =
        "SDDM is configured to use Hyprland, but Hyprland is not enabled. Please enable modules.display.hyprland.";
    }];

    # Enable SDDM display manager
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      package = pkgs.kdePackages.sddm;
      theme = "sddm-astronaut-theme";
      extraPackages = with pkgs; [ sddm-astronaut ];
    };

    # Use Hyprland UWSM session (as shown in error message)
    services.displayManager.defaultSession = "hyprland-uwsm";
  };
}

