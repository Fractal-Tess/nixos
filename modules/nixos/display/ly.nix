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

    # Enable ly display manager with specific configuration
    services.displayManager.ly = {
      enable = true;
      settings = {
        animation = "none";
        clear_password = true;
        hide_borders = false;
        hide_f1_commands = false;
        load_config = true;
        save_file = "/tmp/ly-save";
        term_reset_cursor = true;
      };
    };


    # Ensure proper environment for Hyprland
    services.displayManager.environment = {
      WLR_NO_HARDWARE_CURSORS = "1";
      NIXOS_OZONE_WL = "1";
    };

    # Create a fixed Hyprland UWSM session that stops existing sessions first
    # Based on Reddit solution: https://www.reddit.com/r/hyprland/comments/1i2ap4o/
    environment.etc."wayland-sessions/hyprland-ly-fixed.desktop".text = ''
      [Desktop Entry]
      Name=Hyprland (UWSM Fixed)
      Comment=Hyprland with UWSM session cleanup fix
      Exec=/bin/sh -c "uwsm stop 2>/dev/null || true; uwsm start -F /run/current-system/sw/bin/Hyprland"
      Type=Application
      DesktopNames=Hyprland
    '';

    # Use the fixed UWSM session
    services.displayManager.defaultSession = "hyprland-ly-fixed";
  };
}

