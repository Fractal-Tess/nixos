{ config, lib, pkgs, username, ... }:

with lib;

let
  cfg = config.modules.display.regreet;
  hyprland = config.modules.display.hyprland;

in
{
  options.modules.display.regreet = {
    # Option to enable/disable the ReGreet display manager
    enable = mkEnableOption "ReGreet";

    # Option to enable automatic login without password prompt
    autoLogin = mkEnableOption "ReGreet auto login";
  };

  # Configuration that applies when this module is enabled
  config = mkIf cfg.enable {
    # Check if Hyprland is enabled, otherwise throw an error
    assertions = [{
      assertion = hyprland.enable;
      message =
        "ReGreet is configured to use Hyprland, but Hyprland is not enabled. Please enable modules.display.hyprland.";
    }];

    # Enable regreet as the greeter
    programs.regreet = {
      enable = true;
      theme = { name = username; };
      # Optionally, set the session to Hyprland
      settings = {
        background = {
          path = "/home/fractal-tess/Pictures/wallpapers/1.jpg";
          fit = "Cover";
        };

        commands = {
          reboot = [ "systemctl" "reboot" ];
          poweroff = [ "systemctl" "poweroff" ];
        };

        appearance = { greeting_msg = "Welcome back, ${username}!"; };

        widget.clock = {
          # strftime format argument
          format = "%a %H:%M";

          # How often to update the text
          resolution = "500ms";

          # Use the system timezone from config
          timezone = config.time.timeZone;

          # Ask GTK to make the label at least this wide. This helps keeps the parent element layout and width consistent.
          # Experiment with different widths, the interpretation of this value is entirely up to GTK.
          label_width = 150;
        };
      };
    };
  };
}
