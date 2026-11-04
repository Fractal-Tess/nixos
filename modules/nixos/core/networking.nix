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

      # Reach these oracle sites over NetBird instead of the public internet.
      # Their admin panels only answer requests coming from the mesh.
      hosts."100.91.0.4" = [ "pb-indecisive.fractal-tess.xyz" ];
    };

    services.netbird = {
      enable = mkDefault true;
      package = pkgs.netbird;
      ui.enable = false;
    };
  };
}
