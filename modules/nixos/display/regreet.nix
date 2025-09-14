{ config, lib, username, ... }:

with lib;

let
  cfg = config.modules.display.regreet;
  hyprland = config.modules.display.hyprland;

in {
  options.modules.display.regreet = {
    # Option to enable/disable the ReGreet display manager
    enable = mkEnableOption "ReGreet";

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
    services.greetd.enable = true;

    # Enable regreet as the greeter
    programs.regreet = {
      # Enable regreet
      enable = true;

      cageArgs = [ "-m" "last" ];

      # Configuration with Canta theme and background
      settings = {
        commands = {
          reboot = [ "systemctl" "reboot" ];
          poweroff = [ "systemctl" "poweroff" ];
        };
        background = {
          path = "/var/lib/regreet-backgrounds/evening-sky.png";
          fit = "Cover";
        };
        appearance = {
          theme = "Canta-dark";
          icon_theme = "Canta";
          cursor_theme = "Adwaita";
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
