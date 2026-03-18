{ pkgs, ... }:

{
  systemd.user.services.battery-check = {
    Unit = {
      Description = "Battery level check — notify below 20%, shutdown below 10%";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "/home/%u/nixos/scripts/bin/battery-check";
      Environment = [
        "PATH=/run/current-system/sw/bin:/run/wrappers/bin"
        "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/%U/bus"
      ];
    };
  };

  systemd.user.timers.battery-check = {
    Unit = {
      Description = "Run battery check every minute";
    };
    Timer = {
      OnBootSec = "1min";
      OnUnitActiveSec = "1min";
      Unit = "battery-check.service";
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };
}
