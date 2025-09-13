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

    # Option to enable automatic login without password prompt
    autoLogin = mkEnableOption "ly auto login";
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
    services.displayManager.ly.enable = true;

    # Configure auto login if enabled  
    services.displayManager.autoLogin = mkIf cfg.autoLogin {
      enable = true;
      user = username;
    };

    # Ensure proper environment for Hyprland
    services.displayManager.environment = {
      WLR_NO_HARDWARE_CURSORS = "1";
      NIXOS_OZONE_WL = "1";
    };

    # Use regular Hyprland session
    services.displayManager.defaultSession = "hyprland";
  };
}

