{ config, lib, pkgs, ... }:

with lib;

{
  imports = [ ./adb ./auto_cpu ./filesystemExtraServices ./sshd ./docker ];

  config = {
    # Wireshark
    programs.wireshark.enable = true;
    programs.wireshark.dumpcap.enable = true;
    programs.wireshark.package = pkgs.wireshark;

    # Printing
    services.printing = mkIf config.modules.gui {
      enable = true;
      drivers = with pkgs; [ ]; # Add printer drivers as needed
    };

    # DBus
    services.dbus.enable = true;

    # GVFS
    services.gvfs.enable = true;
  };
}
