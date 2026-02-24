{ osConfig, lib, ... }:

with lib;

let
  # Device-specific monitor configurations
  vdMonitorConfig = ''
    ################
    ### MONITORS ###
    ################

    # vd - Desktop setup
    monitor=DP-1, 2560x1080@75, 0x0, 1 # LG monitor
    monitor=HDMI-A-1, 2560x1440@144, 2560x0, 1 # Acer monitor

    # Hyprland bug
    # monitor=Unknown-1, disable
  '';

  kiwiMonitorConfig = ''
    ################
    ### MONITORS ###
    ################

    # kiwi - External monitor setup
    # Left-to-right: DP-5 (Dell U2717D, 2560x1440, bigger) -> DP-3 (Dell U2414H, 1920x1080)
    monitor=DP-5, 2560x1440@59.95, 0x0, 1
    monitor=DP-3, 1920x1080@60, 2560x0, 1

    # Disable laptop screen when external monitors are connected
    monitor=eDP-1, disable

    # Hyprland bug
    # monitor=Unknown-1, disable
  '';
in
{
  # Export the configurations
  inherit vdMonitorConfig kiwiMonitorConfig;

  # Select device-specific monitor config based on hostname
  deviceMonitorConfig =
    if osConfig.networking.hostName == "vd" then
      vdMonitorConfig
    else if osConfig.networking.hostName == "kiwi" then
      kiwiMonitorConfig
    else
      vdMonitorConfig; # fallback
}
