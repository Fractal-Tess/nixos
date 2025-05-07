{ osConfig, lib, ... }:

with lib;

{
  config = {
    home.file = mkMerge [
      # Zsh configurations
      (mkIf config.zsh.enable { ".zshrc".source = ../../config/zsh/.zshrc; })

      (mkIf config.zsh.p10k {
        ".p10k.zsh".source = ../../config/zsh/.p10k.zsh;
      })
    ];

    # Window manager and UI configurations
    xdg.configFile = mkMerge [
      # Hyprland
      (mkIf
        (osConfig.modules.display.hyprland.enable && config.configFiles.hypr)
        {
          hypr = {
            source = ../../config/hypr;
            recursive = true;
          };
        })

      # Waybar
      (mkIf
        (osConfig.modules.display.waybar.enable && config.configFiles.waybar)
        {
          waybar = {
            source = ../../config/waybar;
            recursive = true;
          };
        })

      # Wofi
      (mkIf config.configFiles.wofi {
        wofi = {
          source = ../../config/wofi;
          recursive = true;
        };
      })
    ];
  };
}
