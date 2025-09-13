{ config, lib, username, ... }:

with lib;

let
  cfg = config.modules.display.ly;
  hyprland = config.modules.display.hyprland;

in
{
  options.modules.display.ly = {
    # Option to enable/disable the ly display manager
    enable = mkEnableOption "ly display manager";
  };

  # Configuration that applies when this module is enabled
  config = mkIf cfg.enable {
    # Check if Hyprland is enabled, otherwise throw an error
    assertions = [{
      assertion = hyprland.enable;
      message =
        "ly is configured to use Hyprland, but Hyprland is not enabled. Please enable modules.display.hyprland.";
    }];

    # Enable ly display manager
    services.displayManager.ly = {
      enable = true;
    };
  };
}

