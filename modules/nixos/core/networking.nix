{ lib, hostname, pkgs, ... }:

with lib;

{
  config = {

    networking = {
      hostName = hostname;
      networkmanager.enable = mkDefault true;
      wireless.enable = mkDefault false;

      # Enable IP forwarding for Docker containers to access VPN networks
      firewall = {
        enable = mkDefault true;
        allowedTCPPorts = mkMerge [ ];
        allowedUDPPorts = mkMerge [ ];

        # Allow Docker traffic
        trustedInterfaces = [ "docker0" "wt0" ];
      };

    };

    services.netbird.enable = mkDefault true;
  };
}

