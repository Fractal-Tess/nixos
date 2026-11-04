{
  lib,
  hostname,
  pkgs,
  ...
}:

with lib;

{
  config = {

    # Enable systemd-resolved for better DNS management
    services.resolved.enable = true;

    networking = {
      hostName = hostname;
      networkmanager.enable = mkDefault true;
      wireless.enable = mkDefault false;

      # DNS configuration for VPN coexistence
      nameservers = [
        "1.1.1.1"
        "8.8.8.8"
      ];
      search = [
        "netbird.cloud"
        "int"
      ];

      # Enable IP forwarding for Docker containers to access VPN networks
      firewall = {
        enable = mkDefault true;
        allowedTCPPorts = mkDefault [ 631 ]; # CUPS printing service
        allowedUDPPorts = mkMerge [ ];

        # Allow Docker traffic
        trustedInterfaces = [
          "docker0"
          "wt0"
        ];
      };

      # Admin-only hostnames on oracle, reached over NetBird: their apps only
      # answer admin requests from the mesh. Never list a hostname a public
      # site fetches from: browsers block public pages from calling private
      # (100.64.0.0/10) addresses.
      hosts."100.91.0.4" = [ "pb-indecisive-admin.fractal-tess.xyz" ];
    };

    services.netbird = {
      enable = mkDefault true;
      package = pkgs.netbird;
      ui.enable = false;
    };
  };
}
