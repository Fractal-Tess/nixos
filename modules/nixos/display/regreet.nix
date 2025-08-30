{ config, lib, username, ... }:

with lib;

let
  cfg = config.modules.display.regreet;
  hyprland = config.modules.display.hyprland;

in {
  options.modules.display.regreet = {
    # Option to enable/disable the ReGreet display manager
    enable = mkEnableOption "ReGreet";

    # Option to enable automatic login without password prompt
    autoLogin = mkEnableOption "ReGreet auto login";

    # Option to enable symlinking backgrounds to /var/lib/regreet-backgrounds
    symlinkBackgrounds = mkEnableOption
      "Symlink backgrounds to /var/lib/regreet-backgrounds for regreet access";
  };

  # Configuration that applies when this module is enabled
  config = mkIf cfg.enable {
    # Check if Hyprland is enabled, otherwise throw an error
    assertions = [{
      assertion = hyprland.enable;
      message =
        "ReGreet is configured to use Hyprland, but Hyprland is not enabled. Please enable modules.display.hyprland.";
    }];

    # Enable greetd service
    services.greetd = {
      enable = true;
      settings = mkIf cfg.autoLogin {
        initial_session = {
          command = "${config.programs.hyprland.package}/bin/Hyprland";
          user = username;
        };
      };
    };

    # Enable regreet as the greeter
    programs.regreet = {
      # Enable regreet
      enable = true;

      cageArgs = [ "-m" "last" ];

      extraCss = ''
        /* Dark theme with main color #258ECE */
        :root {
          --background-color: #0a0a0a;
          --surface-color: #1a1a1a;
          --text-color: #ffffff;
          --text-secondary: #b0b0b0;
          --primary-color: #258ECE;
          --primary-hover: #1a6b9e;
          --accent-color: #3a9ee0;
          --error-color: #ff6b6b;
          --success-color: #51cf66;
          --border-color: #333333;
          --font-family: 'Inter', 'Noto Sans', sans-serif;
          --font-size: 16px;
          --border-radius: 8px;
          --shadow: 0 4px 6px rgba(0, 0, 0, 0.3);
        }

        /* Global dark theme application */
        * {
          color-scheme: dark;
        }

        /* Main window and application styling */
        window {
          background-color: var(--background-color);
          color: var(--text-color);
        }

        /* Main container and box styling */
        box, container {
          background-color: var(--background-color);
          color: var(--text-color);
        }

        /* Header styling */
        headerbar, .titlebar {
          background-color: var(--surface-color);
          border-bottom: 1px solid var(--border-color);
          box-shadow: var(--shadow);
        }

        /* Clock widget styling */
        .clock, clock {
          background-color: var(--surface-color);
          color: var(--primary-color);
          border: 1px solid var(--border-color);
          border-radius: var(--border-radius);
          padding: 12px 16px;
          box-shadow: var(--shadow);
        }

        /* User selection styling */
        .user-selector, .user-list, list {
          background-color: var(--surface-color);
          border: 2px solid var(--border-color);
          border-radius: var(--border-radius);
          transition: all 0.2s ease;
        }

        .user-selector:hover, .user-list:hover, list row:hover {
          border-color: var(--primary-color);
          box-shadow: 0 0 0 3px rgba(37, 142, 206, 0.1);
        }

        .user-selector:focus, .user-list:focus, list row:focus {
          border-color: var(--primary-color);
          box-shadow: 0 0 0 3px rgba(37, 142, 206, 0.2);
        }

        /* Session selector styling */
        .session-selector, .session-list, combobox {
          background-color: var(--surface-color);
          border: 1px solid var(--border-color);
          border-radius: var(--border-radius);
          color: var(--text-color);
        }

        .session-selector:hover, .session-list:hover, combobox:hover {
          border-color: var(--primary-color);
        }

        /* Password entry styling */
        .password-entry, entry, .password-field {
          background-color: var(--surface-color);
          border: 2px solid var(--border-color);
          border-radius: var(--border-radius);
          color: var(--text-color);
          padding: 12px 16px;
          transition: all 0.2s ease;
        }

        .password-entry:focus, entry:focus, .password-field:focus {
          border-color: var(--primary-color);
          box-shadow: 0 0 0 3px rgba(37, 142, 206, 0.2);
          outline: none;
        }

        /* Button styling */
        button, .btn {
          background-color: var(--primary-color);
          color: white;
          border: none;
          border-radius: var(--border-radius);
          padding: 12px 24px;
          font-weight: 600;
          cursor: pointer;
          transition: all 0.2s ease;
          box-shadow: var(--shadow);
        }

        button:hover, .btn:hover {
          background-color: var(--primary-hover);
          transform: translateY(-1px);
          box-shadow: 0 6px 12px rgba(37, 142, 206, 0.3);
        }

        button:active, .btn:active {
          transform: translateY(0);
        }

        /* Power button styling */
        .power-button, .power-btn {
          background-color: var(--surface-color);
          color: var(--text-color);
          border: 1px solid var(--border-color);
        }

        .power-button:hover, .power-btn:hover {
          background-color: var(--error-color);
          color: white;
          border-color: var(--error-color);
        }

        /* Greeting message styling */
        .greeting-message, .greeting, label {
          color: var(--primary-color);
          font-size: 1.2em;
          font-weight: 600;
          text-align: center;
          margin: 20px 0;
        }

        /* Error message styling */
        .error-message, .error {
          background-color: rgba(255, 107, 107, 0.1);
          color: var(--error-color);
          border: 1px solid var(--error-color);
          border-radius: var(--border-radius);
          padding: 12px 16px;
          margin: 16px 0;
        }

        /* Success message styling */
        .success-message, .success {
          background-color: rgba(81, 207, 102, 0.1);
          color: var(--success-color);
          border: 1px solid var(--success-color);
          border-radius: var(--border-radius);
          padding: 12px 16px;
          margin: 16px 0;
        }

        /* Dropdown styling */
        dropdown, popover, menu {
          background-color: var(--surface-color);
          border: 1px solid var(--border-color);
          border-radius: var(--border-radius);
          box-shadow: var(--shadow);
        }

        dropdown item, popover item, menu item {
          color: var(--text-color);
          padding: 8px 16px;
        }

        dropdown item:hover, popover item:hover, menu item:hover {
          background-color: var(--primary-color);
          color: white;
        }

        /* Input field styling */
        entry, input, .input-field {
          background-color: var(--surface-color);
          border: 2px solid var(--border-color);
          border-radius: var(--border-radius);
          color: var(--text-color);
          padding: 12px 16px;
          transition: all 0.2s ease;
        }

        entry:focus, input:focus, .input-field:focus {
          border-color: var(--primary-color);
          box-shadow: 0 0 0 3px rgba(37, 142, 206, 0.2);
        }

        /* Scrollbar styling */
        scrollbar, .scrollbar {
          background-color: var(--surface-color);
        }

        scrollbar slider, .scrollbar slider {
          background-color: var(--primary-color);
          border-radius: 4px;
        }

        scrollbar slider:hover, .scrollbar slider:hover {
          background-color: var(--primary-hover);
        }

        /* List and tree view styling */
        treeview, listbox {
          background-color: var(--surface-color);
          color: var(--text-color);
        }

        treeview row, listbox row {
          background-color: var(--surface-color);
          color: var(--text-color);
        }

        treeview row:hover, listbox row:hover {
          background-color: var(--primary-color);
          color: white;
        }

        /* Frame and separator styling */
        frame, separator {
          background-color: var(--border-color);
          border-color: var(--border-color);
        }

        /* Override any light theme defaults */
        * {
          background-color: var(--background-color) !important;
          color: var(--text-color) !important;
        }

        /* Specific overrides for common elements */
        label, button, entry, combobox, listbox, treeview {
          background-color: var(--surface-color) !important;
          color: var(--text-color) !important;
        }

        /* Ensure buttons have proper styling */
        button {
          background-color: var(--primary-color) !important;
          color: white !important;
        }

        /* GTK4 specific styling */
        .window-frame {
          background-color: var(--background-color);
        }

        .window-frame:backdrop {
          background-color: var(--background-color);
        }

        /* Ensure all text is visible */
        * {
          color: var(--text-color) !important;
        }

        /* Override any inherited light themes */
        .light, .light-theme {
          background-color: var(--background-color) !important;
          color: var(--text-color) !important;
        }

        /* Force dark appearance */
        .dark, .dark-theme {
          background-color: var(--background-color) !important;
          color: var(--text-color) !important;
        }
      '';

      # Set the session to Hyprland and configure dark theme
      settings = {
        background = {
          path = "/var/lib/regreet-backgrounds/1.jpg";
          fit = "Cover";
        };
        commands = {
          reboot = [ "systemctl" "reboot" ];
          poweroff = [ "systemctl" "poweroff" ];
        };
        appearance = {
          greeting_msg = "Welcome back, ${username}!";
          theme = "dark";
          icon_theme = "Adwaita";
          cursor_theme = "Adwaita";
          font = "Inter 16";
        };
        "widget.clock" = {
          format = "%a %H:%M";
          resolution = "500ms";
          timezone = config.time.timeZone;
          label_width = 150;
        };
        # Additional modern regreet settings
        "widget.power" = {
          show_suspend = true;
          show_hibernate = true;
        };
        "widget.session" = {
          show_remember = true;
          default_session = "hyprland";
        };
        # Environment variables for sessions
        env = {
          GTK_THEME = "Adwaita:dark";
          XDG_CURRENT_DESKTOP = "Hyprland";
          XDG_SESSION_TYPE = "wayland";
          GTK_USE_PORTAL = "0";
          GDK_DEBUG = "no-portals";
        };
        # Session configuration
        session = {
          hyprland = {
            command = "${config.programs.hyprland.package}/bin/Hyprland";
            env = {
              XDG_CURRENT_DESKTOP = "Hyprland";
              XDG_SESSION_TYPE = "wayland";
              GTK_THEME = "Adwaita:dark";
            };
          };
        };
      };
    };

    # Only set up symlinks if symlinkBackgrounds is enabled
    systemd.tmpfiles.rules = mkIf cfg.symlinkBackgrounds
      [ "d /var/lib/regreet-backgrounds 0755 root root -" ];

    # Symlink backgrounds to /var/lib/regreet-backgrounds so it's accessible to regreet
    system.activationScripts.regreetBackgrounds = mkIf cfg.symlinkBackgrounds ''
      mkdir -p /var/lib/regreet-backgrounds
      chown -R fractal-tess:users /var/lib/regreet-backgrounds
      rm -rf /var/lib/regreet-backgrounds/*
      for img in /home/${username}/nixos/backgrounds/*; do
        ln -f "$img" /var/lib/regreet-backgrounds/
      done
      chmod -R a+r /var/lib/regreet-backgrounds
    '';
  };
}
