{ lib, ... }:

with lib;

{
  options = {
    # Define options for each config file
    zsh = {
      enable = mkEnableOption "Zsh configuration";
      p10k = mkEnableOption "Powerlevel10k for Zsh";
    };

    configFiles = {
      hypr = mkEnableOption "Hyprland configuration";
      waybar = mkEnableOption "Waybar configuration";
      wofi = mkEnableOption "Wofi configuration";
    };
  };
}
