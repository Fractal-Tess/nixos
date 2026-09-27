{
  config,
  lib,
  pkgs,
  username,
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
      # Clock script (reads calendar events via GObject introspection)
      (pkgs.python3.withPackages (ps: [ ps.pygobject3 ]))
      pkgs.curl
      pkgs.fish
      pkgs.jq
      pkgs.libnotify
      pkgs.procps
      "/run/wrappers"
      # Everything else modules and click handlers call (swaync-client,
      # hyprctl, pamixer, blueman-manager, gnome-calendar, …)
      "/run/current-system/sw"
      "/etc/profiles/per-user/${username}"
    ];
  };
}
