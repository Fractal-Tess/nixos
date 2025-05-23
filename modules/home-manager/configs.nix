{ osConfig, lib, ... }:

with lib;

{
  home.file = {
    # Zsh config
    ".zshrc".source = ../../config/zsh/.zshrc;

    # Zsh - p10k config
    ".p10k.zsh".source = ../../config/zsh/.p10k.zsh;
  };

  # Hyprland
  xdg.configFile.hypr = mkIf osConfig.modules.display.hyprland.enable {
    source = ../../config/hyprland;
    recursive = true;
  };

  # Waybar
  xdg.configFile.waybar = mkIf osConfig.modules.display.waybar.enable {
    source = ../../config/waybar;
    recursive = true;
  };

  # Wofi
  xdg.configFile.wofi = {
    source = ../../config/wofi;
    recursive = true;
  };

  home.activation.linkBackgrounds = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ln -sf /usr/share/backgrounds ${toString (./backgrounds)}
  '';
}
