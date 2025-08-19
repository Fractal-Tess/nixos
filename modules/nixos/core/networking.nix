{ lib, hostname, ... }:

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

        # Allow Docker containers to access VPN networks
        extraCommands = ''
          # Allow Docker bridge network to access Netbird VPN
          iptables -A FORWARD -i docker0 -o wt0 -j ACCEPT
          iptables -A FORWARD -o docker0 -i wt0 -j ACCEPT

          # Allow Docker containers to use Netbird DNS
          iptables -A OUTPUT -d 100.91.242.113 -j ACCEPT
          iptables -A INPUT -s 100.91.242.113 -j ACCEPT

          # Allow traffic to Netbird network range
          iptables -A FORWARD -d 100.91.0.0/16 -j ACCEPT
          iptables -A FORWARD -s 100.91.0.0/16 -j ACCEPT
        '';
      };

    };

    services.netbird.enable = mkDefault true;
  };
}

