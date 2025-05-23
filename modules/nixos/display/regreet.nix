{ config, lib, username, ... }:

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

    services.greetd = {
      enable = true;
      settings = mkIf cfg.autoLogin {
        initial_session = {
          command = "${config.programs.hyprland.package}/bin/Hyprland";
          user = username;
        };
        default_session = {
          command = "${config.programs.regreet.package}/bin/regreet";
          user = "greeter";
        };
      };
    };

    # Enable regreet as the greeter
    programs.regreet = {
      # Enable regreet
      enable = true;

      cageArgs = [ "-m" "last" ];

      extraCss = ''
        /* Base dark theme variables */
        :root {
          --background-color: #121212;
          --text-color: #eee;
          --primary-color: #809fff;
          --font-family: 'Noto Sans', sans-serif;
          --font-size: 16px;
        }

        /* Apply dark theme to Regreet container */
        .regreet-dark-theme {
          background-color: var(--background-color);
          color: var(--text-color);
          font-family: var(--font-family);
          font-size: var(--font-size);
        }

        /* Style Regreet internal parts */
        regreet-component::part(header),
        regreet-component::part(footer),
        regreet-component::part(content) {
          background-color: var(--background-color);
          color: var(--text-color);
        }

        /* Links and buttons */
        .regreet-dark-theme a {
          color: var(--primary-color);
          text-decoration: none;
        }

        .regreet-dark-theme button {
          background-color: var(--primary-color);
          color: var(--background-color);
          border: none;
          padding: 0.5em 1em;
          border-radius: 4px;
          cursor: pointer;
        }
      '';

      # Set the session to Hyprland
      settings = {
        background = {
          path = "/home/${username}/nixos/backgrounds/1.jpg";
          fit = "Cover";
        };
        commands = {
          reboot = [ "systemctl" "reboot" ];
          poweroff = [ "systemctl" "poweroff" ];
        };
        appearance = { greeting_msg = "Welcome back, ${username}!"; };
        "widget.clock" = {
          format = "%a %H:%M";
          resolution = "500ms";
          timezone = config.time.timeZone;
          label_width = 150;
        };
      };
    };
  };
}
