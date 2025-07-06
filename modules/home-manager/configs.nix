{ osConfig, lib, ... }:

with lib;

let
  waybarConfig = if osConfig.networking.hostName == "neo" then
    ../../config/waybar/config-neo.jsonc
  else
    ../../config/waybar/config-vd.jsonc;
in {
  # Hyprland
  xdg.configFile.hypr = mkIf osConfig.modules.display.hyprland.enable {
    source = ../../config/hyprland;
    recursive = true;
  };

  # Waybar (host-specific config.jsonc, shared style.css)
  xdg.configFile."waybar/config.jsonc" =
    mkIf osConfig.modules.display.waybar.enable { source = waybarConfig; };
  xdg.configFile."waybar/style.css" =
    mkIf osConfig.modules.display.waybar.enable {
      source = ../../config/waybar/style.css;
    };
  # Add more shared files/scripts as needed

  # Wofi
  xdg.configFile.wofi = {
    source = ../../config/wofi;
    recursive = true;
  };

  # zsh
  home.file = {
    # Zsh config
    ".zshrc".source = ../../config/zsh/.zshrc;

    # Zsh - p10k config
    ".p10k.zsh".source = ../../config/zsh/.p10k.zsh;
  };

}
