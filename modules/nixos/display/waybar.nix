{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.modules.display.waybar;
  hyprlandEnabled = config.modules.display.hyprland.enable;
  waybarPackage =
    if hyprlandEnabled then
      pkgs.waybar.overrideAttrs (oldAttrs: {
        mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
      })
    else
      pkgs.waybar;
in

{
  options.modules.display.waybar = {
    enable = mkEnableOption "Waybar";
  };

  config = mkIf cfg.enable {
    programs.waybar = {
      enable = true;
      package = waybarPackage;
    };

    # Dependencies used by Waybar's custom scripts and click handlers. The sudo
    # wrapper is required for privileged controls such as CPU boost.
    systemd.user.services.waybar.path = [
      pkgs.fish
      pkgs.libnotify
      pkgs.procps
      "/run/wrappers"
    ];
  };
}
