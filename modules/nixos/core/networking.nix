{ lib, hostname, ... }:

with lib;

{
  config = {

    networking = {
      hostName = hostname;
      networkmanager.enable = mkDefault true;
      wireless.enable = mkDefault false;

      firewall = {
        enable = mkDefault true;
        allowedTCPPorts = mkDefault [ ];
        allowedUDPPorts = mkDefault [ ];
      };
    };

    services.netbird.enable = mkDefault true;
  };
}

