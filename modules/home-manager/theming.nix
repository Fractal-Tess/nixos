{ pkgs, osConfig, lib, ... }:
with lib;

{

  # Theming - only enable when display/GUI is available
  gtk = with pkgs; mkIf (osConfig.modules.display.hyprland.enable or false) {
    enable = true;
    theme = {
      name = "Nordic-darker";
      package = nordic;
    };
    iconTheme = {
      name = "Nordzy-dark";
      package = nordzy-icon-theme;
    };
    cursorTheme = {
      name = "Nordzy-cursors";
      package = nordzy-cursor-theme;
      size = 32;
    };
  };

  qt = mkIf (osConfig.modules.display.hyprland.enable or false) {
    enable = true;
    platformTheme.name = "gtk3";
  };
}
