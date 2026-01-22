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

    # kiwi - Laptop with external monitor setup
    monitor=eDP-1, 1920x1080@60, 0x0, 1 # Laptop monitor (left)
    monitor=DP-1, 2560x1440@59.95, 1920x0, 1 # Dell U2717D monitor (middle)
    monitor=HDMI-A-1, 2560x1440@59.95, 3840x0, 1 # Dell U2717D monitor (right)

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
