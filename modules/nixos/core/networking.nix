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
        allowedTCPPorts = mkMerge [ ];
        allowedUDPPorts = mkMerge [ ];
      };
    };

    services.netbird.enable = mkDefault true;
  };
}

