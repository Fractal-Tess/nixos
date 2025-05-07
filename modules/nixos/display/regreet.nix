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

    # services.greetd = {
    #   enable = true;
    #   settings = mkIf cfg.autoLogin {
    #     initial_session = {
    #       command = "${config.programs.hyprland.package}/bin/Hyprland";
    #       user = username;
    #     };
    #     default_session = {
    #       command = "${config.programs.regreet.package}/bin/regreet";
    #       user = "greeter";
    #     };
    #   };
    # };

    # Enable regreet as the greeter
    programs.regreet = {
      # Enable regreet
      enable = true;

      cageArgs = [ "-m" "last" ];

      # Set the theme to the user's name
      theme = { name = username; };

      # Set the session to Hyprland
      settings = ''
        [background]
        path = "/home/fractal-tess/nixos/backgrounds/1.jpg"
        fit = "Cover"

        [commands]
        reboot = ["systemctl", "reboot"]
        poweroff = ["systemctl", "poweroff"]

        [appearance]
        greeting_msg = "Welcome back, ${username}!"

        [widget.clock]
        format = "%a %H:%M"
        resolution = "500ms"
        timezone = "${config.time.timeZone}"
        label_width = 150

        [GTK]
        # Whether to use the dark theme
        application_prefer_dark_theme = true

        # Cursor theme name
        cursor_theme_name = "Adwaita"

        # Font name and size
        font_name = "Cantarell 16"

        # Icon theme name
        icon_theme_name = "Adwaita"

        # GTK theme name
        theme_name = "Adwaita"

      '';

    };
  };
}
