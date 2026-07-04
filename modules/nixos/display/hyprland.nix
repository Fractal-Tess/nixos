{
  config,
  lib,
  pkgs,
  username,
  ...
}:

with lib;
let
  cfg = config.modules.display.hyprland;
in
{
  # Options for Hyprland configuration
  options.modules.display.hyprland = {
    enable = mkEnableOption "Hyprland";
  };

  config = mkIf cfg.enable {
    # Enable Hyprland compositor
    programs.hyprland = {
      enable = true;
      portalPackage = pkgs.xdg-desktop-portal-hyprland;

      # Enable Xwayland
      xwayland.enable = true;
      # Enable UWSM
      withUWSM = true;
    };

    # Hardware acceleration
    hardware.graphics = {
      enable = true;
    };

    # Enable Hyprlock
    programs.hyprlock.enable = true;
    # Enable Hypridle
    services.hypridle.enable = true;

    # Enable XDG Desktop Portal for sandboxed/Wayland apps
    xdg.portal = {
      enable = mkDefault true;
      #   # Use portal for xdg-open
      xdgOpenUsePortal = mkDefault true;
      #   # Add GTK portal backend
      extraPortals = mkDefault [ pkgs.xdg-desktop-portal-gtk ];
    };

    # Add kitty terminal to system packages
    environment.systemPackages = [
      pkgs.kitty
      pkgs.ncurses
    ];
    # Enable dconf for GTK/Flatpak app settings
    programs.dconf.enable = true;

    # Add nvidia driver for
    services.xserver.videoDrivers = mkMerge [
      (mkIf config.modules.drivers.nvidia.enable [ "nvidia" ])
      (mkIf config.modules.drivers.amd.enable [ "amdgpu" ])
    ];

    #============================================================================
    # SUSPEND/RESUME RECOVERY
    #============================================================================
    # After S3 suspend/resume, Hyprland can lose its GPU/DRM context and fall
    # back to stock defaults even though the config files are on disk. This is a
    # known issue with Hyprland + AMDGPU + S3 sleep.
    #
    # This hook runs as root after resume, discovers the live Hyprland instance
    # socket, and forces a config reload for the user's session.
    powerManagement.resumeCommands = ''
      user="${username}"
      uid="$(${pkgs.coreutils}/bin/id -u "$user" 2>/dev/null || true)"
      [ -n "$uid" ] || exit 0

      runtime="/run/user/$uid"
      hypr_dir="$runtime/hypr"

      # No Hyprland instance running — nothing to reload
      [ -d "$hypr_dir" ] || exit 0

      # Give GPU/display devices time to settle after resume
      ${pkgs.coreutils}/bin/sleep 2

      # Try newest instances first. Stale sockets can remain after Hyprland
      # crashes during suspend, so stop after the first successful reload.
      ${pkgs.findutils}/bin/find "$hypr_dir" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %f\n' \
        | ${pkgs.coreutils}/bin/sort -rn \
        | while read -r _ sig; do
          [ -n "$sig" ] || continue
          ${pkgs.util-linux}/bin/runuser -u "$user" -- \
            env XDG_RUNTIME_DIR="$runtime" HYPRLAND_INSTANCE_SIGNATURE="$sig" \
            ${pkgs.hyprland}/bin/hyprctl reload && exit 0
        done
      exit 0
    '';
  };
}
