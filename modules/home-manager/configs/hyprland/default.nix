{ osConfig, lib, pkgs, ... }:

with lib;

let
  # Import all hyprland configuration modules
  monitorsConfig = import ./monitors.nix { inherit osConfig lib; };
  keybindingsConfig = import ./keybindings.nix { };
  gesturesConfig = import ./gestures.nix { };
  settingsConfig = import ./settings.nix { };
  windowsConfig = import ./windows.nix { };
  startupConfig = import ./startup.nix { };

  # Generate combined hyprland configuration
  hyprlandConfig = pkgs.writeText "hyprland.conf" ''
    ${monitorsConfig.deviceMonitorConfig}

    ${settingsConfig.settings}

    ${gesturesConfig.gestures}

    ${keybindingsConfig.keybindings}

    ${windowsConfig.windows}

    ${startupConfig.startup}
  '';

in
{
  # Hyprland - Combined configuration with device-specific monitors
  home.file.".config/hypr/hyprland.conf" = mkIf osConfig.modules.display.hyprland.enable {
    source = hyprlandConfig;
  };

  # Other Hyprland config files (hypridle, hyprlock, etc.)
  xdg.configFile."hypr/hypridle.conf" = mkIf osConfig.modules.display.hyprland.enable {
    source = ./hypridle.conf;
  };

  xdg.configFile."hypr/hyprlock.conf" = mkIf osConfig.modules.display.hyprland.enable {
    source = ./hyprlock.conf;
  };

  # Satty - Screenshot annotation tool config
  xdg.configFile."satty/config.toml" = mkIf osConfig.modules.display.hyprland.enable {
    source = ../satty/config.toml;
  };
}