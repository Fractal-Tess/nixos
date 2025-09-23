{ osConfig, lib, pkgs, ... }:

{
  imports = [
    ./hyprland
    ./waybar
    ./wofi
    ./zsh
  ];
}