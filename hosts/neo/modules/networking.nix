{ pkgs, ... }: {
  # Networking
  networking.hostName = "neo";
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;
  programs.nm-applet.enable = true;
  services.netbird.enable = true;

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 9 22 ];
  networking.firewall.allowedUDPPorts = [ 9 22 ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
}
