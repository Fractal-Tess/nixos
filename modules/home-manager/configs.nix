{ osConfig, lib, ... }:

with lib;

{
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # Zsh config
    ".zshrc".source = ../../config/zsh/.zshrc;

    # Zsh - p10k config
    ".p10k.zsh".source = ../../config/zsh/.p10k.zsh;
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
