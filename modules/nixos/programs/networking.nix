{ config, lib, pkgs, ... }:

with lib;

let cfg = config.modules.services.networking;
in {
  options.modules.services.networking.enable =
    mkEnableOption "Networking utilities";

  # Configure networking utilities if enabled
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      ngrok # Expose local servers to the internet
      nmap # Network discovery and security auditing
      networkmanagerapplet # Network manager system tray
      openvpn # Open-source VPN solution
      wakeonlan # Wake devices using Wake-on-LAN
      hping # Command-line TCP/IP packet assembler/analyzer
      oha # HTTP load generator
      inetutils # Common networking utilities (ping, ifconfig, etc.)
      iproute2 # ip, ss, etc.
      traceroute # Traceroute utility
      mtr # Network diagnostic tool
      curl # Data transfer tool
      wget # Data transfer tool
      # Add more as needed
    ];
  };
}
