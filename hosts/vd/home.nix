{ pkgs, username, lib, osConfig, ... }:

with lib;
let cfg = osConfig;
in {
  imports = [ ../../modules/home-manager/default.nix ];

  # Home Manager
  home.username = username;
  home.homeDirectory = "/home/${username}";

  # File sync
  services.syncthing.enable = true;

  # Eenvironment variables
  home.sessionVariables = {
    GTK_THEME = "Nordic";
    XCURSOR_THEME = "Nordzy-cursors";
    XCURSOR_SIZE = "24";

    # Silence direnv env loading ouput
    DIRENV_LOG_FORMAT = "";

    # If cursor becomes invisible
    # WLR_NO_HARDWARE_CURSORS = "1";

    # Hint to electron apps to use wayland
    NIXOS_OZONE_WL = "1";

    # Editor
    VISUAL = "nvim";
    SUDO_EDITOR = "nvim";
    EDITOR = "nvim";

    # Firefox
    MOZ_USE_WAYLAND = 1;
    MOZ_USE_XINPUT2 = 1;
  };

  # Theming
  gtk = {
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

  qt = {
    enable = true;
    platformTheme.name = "gtk";
  };

  home.packages = with pkgs; [ ];

  home.stateVersion = "24.05";

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
  };
  xdg.configFile.hypr = mkIf cfg.modules.display.hyprland.enable {
    source = ../../modules/nixos/display/hyprland/config;
    recursive = true;
  };
  xdg.configFile.waybar = mkIf cfg.modules.display.waybar.enable {
    source = ../../modules/nixos/display/waybar/config;
    recursive = true;
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. If you don't want to manage your shell through Home
  # Manager then you have to manually source 'hm-session-vars.sh' located at
  # either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/fractal-tess/etc/profile.d/hm-session-vars.sh
  #

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
