{
  pkgs,
  osConfig,
  lib,
  ...
}:

with lib;

let
  theme = import ./configs/theme/palette.nix;
in
{
  gtk =
    with pkgs;
    mkIf (osConfig.modules.display.hyprland.enable or false) {
      enable = true;
      theme = {
        name = theme.gtk.themeName;
        package = adw-gtk3;
      };
      iconTheme = {
        name = theme.gtk.iconThemeName;
        package = papirus-icon-theme;
      };
      cursorTheme = {
        name = theme.gtk.cursorThemeName;
        package = bibata-cursors;
        size = theme.gtk.cursorSize;
      };
      font = {
        name = theme.fonts.sans;
        size = 11;
      };
    };

  qt = mkIf (osConfig.modules.display.hyprland.enable or false) {
    enable = true;
    platformTheme.name = "gtk3";
    style.name = "adwaita-dark";
  };
}
