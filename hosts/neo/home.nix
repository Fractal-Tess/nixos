{ pkgs, username, osConfig, lib, ... }:
with lib; {
  imports = [ ../../modules/home-manager/default.nix ];

  # Home Manager 
  home.username = username;
  home.homeDirectory = "/home/${username}";

  # Theming
  gtk = mkIf osConfig.modules.template.desktop {
    enable = true;
    theme = {
      name = "Nordic-darker";
      package = pkgs.nordic;
    };
    iconTheme = {
      name = "Nordzy-dark";
      package = pkgs.nordzy-icon-theme;
    };
    cursorTheme = {
      name = "Nordzy-cursors";
      package = pkgs.nordzy-cursor-theme;
      size = 32;
    };
  };

  # qt = {
  #   enable = true;
  #   platformTheme.name = "gtk";
  # };

  home.stateVersion = "24.05";

  home.packages = [ ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';


    # Zsh - p10k config
    ".p10k.config.zsh".source = ../../config/zsh/.p10k.config.zsh;
  };

  # Hyprland
  xdg.configFile.hypr = mkIf osConfig.modules.display.hyprland.enable {
    source = ../../config/hypr;
    recursive = true;
  };

  # Waybar
  xdg.configFile.waybar = mkIf osConfig.modules.display.waybar.enable {
    source = ../../config/waybar;
    recursive = true;
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
