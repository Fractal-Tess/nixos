{ config, lib, hostname, ... }:

with lib;

let cfg = config.modules.networking;
in {
  # Networking
  options.modules.networking = {

    # Networking is enabled by default
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable networking";
    };

    # NetworkManager
    networkmanager = {
      # NetworkManager is enabled by default
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable NetworkManager";
      };
    };

    # Wireless
    wireless = {
      # Wireless is disabled by default
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable wireless support via wpa_supplicant";
      };
    };

    # nm-applet
    nm-applet = {
      # nm-applet is disabled by default
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable nm-applet";
      };
    };

    # Firewall 
    firewall = {
      # Firewall is enabled by default
      enabled = mkOption {
        type = types.bool;
        default = true;
        description = "Enable firewall";
      };

      allowedPorts = mkOption {
        type = types.listOf types.int;
        default = [ ];
        description = "List of allowed ports";
      };

      extraCommands = mkOption {
        type = types.str;
        # iptables -I INPUT 1 -i docker0 -p tcp -d 172.17.0.1 -j ACCEPT
        # iptables -I INPUT 2 -i docker0 -p udp -d 172.17.0.1 -j ACCEPT
        default = "";
        description = "Extra commands to run after the firewall is set up";
      };
    };

    # VPN 
    vpn = {
      netbird = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable netbird";
        };
      };
    };
  };
  config = mkIf cfg.enable {
    assertions = [{
      assertion = !(cfg.networkmanager.enable && cfg.wireless.enable);
      message = "NetworkManager and wireless support are mutually exclusive";
    }];

    # Networking
    networking.hostName = hostname;
    networking.wireless.enable = cfg.wireless.enable;
    networking.networkmanager.enable = cfg.networkmanager.enable;
    programs.nm-applet.enable = cfg.nm-applet.enable;

    # Firewall
    networking.firewall = {
      enable = cfg.firewall.enabled;
      allowedTCPPorts = cfg.firewall.allowedPorts;
      allowedUDPPorts = cfg.firewall.allowedPorts;
      extraCommands = cfg.firewall.extraCommands;
    };
    # Or disable the firewall altogether.
    # networking.firewall.enable = false;

    # Configure network proxy if necessary
    # networking.proxy.default = "http://user:password@proxy:port/";
    # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    # VPN
    services.netbird.enable = cfg.vpn.netbird.enable;
    # TODO: Add wireguard client
  };
}

