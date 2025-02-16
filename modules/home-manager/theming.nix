{ pkgs, osConfig, lib, ... }:
with lib;

{

  # Theming
  gtk = with pkgs; {
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

  qt = {
    enable = true;
    platformTheme.name = "gtk";
  };
}
