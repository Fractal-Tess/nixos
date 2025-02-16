{ pkgs, username, lib, osConfig, ... }:

with lib;
let cfg = osConfig;
in {
  imports = [
    ../../modules/home-manager/default.nix
    ../../modules/home-manager/configs.nix
    ../../modules/home-manager/theming.nix
  ];

  # Home Manager
  home.username = username;
  home.homeDirectory = "/home/${username}";

  # Has to exist so other home manager modules can mkMerge
  home.packages = with pkgs; [ ];

  # Home manager version - don't change this
  home.stateVersion = "24.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
