{ config, lib, pkgs, username, ... }:

with lib;

let
  cfg = config.modules.display.sddm;
  hyprland = config.modules.display.hyprland;

  custom-sddm-astronaut =
    pkgs.sddm-astronaut.override { embeddedTheme = "pixel_sakura"; };

  westonIni = pkgs.writeText "weston.ini" ''
    [keyboard]
    keymap_layout=us
    keymap_model=pc104
    keymap_options=terminate:ctrl_alt_bksp
    keymap_variant=

    [libinput]
    enable-tap=true
    left-handed=false

    [output]
    name=eDP-1
    mode=off

    [output]
    name=DP-1
    mode=2560x1440@59.95

    [output]
    name=HDMI-A-1
    mode=1920x1080@60
  '';
in {
  options.modules.display.sddm = {
    # Option to enable/disable SDDM display manager
    enable = mkEnableOption "SDDM display manager";
  };

  # Configuration that applies when this module is enabled
  config = mkIf cfg.enable {
    # Check if Hyprland is enabled, otherwise throw an error
    assertions = [{
      assertion = hyprland.enable;
      message =
        "SDDM is configured to use Hyprland, but Hyprland is not enabled. Please enable modules.display.hyprland.";
    }];

    # Enable SDDM display manager
    services.displayManager.sddm = {
      enable = true;
      wayland = {
        enable = true;
        compositor = "weston";
        compositorCommand = "${pkgs.weston}/bin/weston --shell=kiosk -c ${westonIni}";
      };
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
      };
      extraPackages = with pkgs; [ custom-sddm-astronaut ];
    };

    environment.systemPackages = with pkgs;
      [
        custom-sddm-astronaut
        # kdePackages.qtmultimedia
      ];

    # Use Hyprland session
    services.displayManager.defaultSession = "hyprland";
  };
}

