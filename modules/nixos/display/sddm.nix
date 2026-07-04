{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.modules.display.sddm;
  hyprland = config.modules.display.hyprland;

  custom-sddm-astronaut = pkgs.sddm-astronaut.override { embeddedTheme = "pixel_sakura"; };
in
{
  options.modules.display.sddm = {
    # Option to enable/disable SDDM display manager
    enable = mkEnableOption "SDDM display manager";
  };

  # Configuration that applies when this module is enabled
  config = mkIf cfg.enable {
    # Check if Hyprland is enabled, otherwise throw an error
    assertions = [
      {
        assertion = hyprland.enable;
        message = "SDDM is configured to use Hyprland, but Hyprland is not enabled. Please enable modules.display.hyprland.";
      }
    ];

    # Enable SDDM display manager
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      package = pkgs.kdePackages.sddm;
      autoNumlock = true;
      enableHidpi = true;
      theme = "sddm-astronaut-theme";
      settings = {
        Theme = {
          Current = "sddm-astronaut-theme";
          CursorTheme = "Bibata-Modern-Ice";
          CursorSize = 24;
        };
        Users = {
          RememberLastSession = false;
        };
      };
      extraPackages = with pkgs; [ custom-sddm-astronaut ];
    };

    environment.systemPackages = with pkgs; [
      custom-sddm-astronaut
      # kdePackages.qtmultimedia
    ];

    # Use Hyprland session via UWSM (User-space Wayland Session Manager)
    # UWSM properly manages the Hyprland lifecycle across suspend/resume,
    # preventing config reset after S3 sleep on AMD GPU laptops.
    services.displayManager.defaultSession = "hyprland-uwsm";
  };
}
