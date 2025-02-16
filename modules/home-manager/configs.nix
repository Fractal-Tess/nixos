{ osConfig, lib, ... }:
with lib; {
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
}
