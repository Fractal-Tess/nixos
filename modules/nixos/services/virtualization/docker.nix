{ config, lib, pkgs, username, ... }:

with lib;

let cfg = config.modules.services.virtualization.docker;
in {
  options.modules.services.virtualization.docker = {
    enable = mkEnableOption "Docker";
    rootless = mkEnableOption "Rootless Docker";
    nvidia = mkEnableOption "Nvidia support";
    devtools = mkEnableOption "Devtools";

    dns = mkOption {
      type = types.listOf types.str;
      default = [ "100.91.242.113" "1.1.1.1" "1.0.0.1" "8.8.8.8" "8.8.4.4" ];
      description =
        "DNS servers to use for the Docker daemon (Netbird DNS first, then fallbacks)";
    };

    useNetbirdDNS = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to prioritize Netbird DNS for Docker containers";
    };
  };

  # Configure the Docker service if enabled
  config = mkIf cfg.enable {
    # Add the user to the docker group
    users.extraGroups.docker.members = mkDefault [ username ];

    # Enable the Nvidia container toolkit if Nvidia support is enabled
    hardware.nvidia-container-toolkit.enable = cfg.nvidia;

    # The underlying Docker implementation to use.
    virtualisation.oci-containers.backend = mkDefault "docker";

    # Configure the Docker virtualisation
    virtualisation.docker = {
      enable = true;
      package = (pkgs.docker.override (args: { buildxSupport = true; }));
      # This is required for containers which are created with the 
      # --restart=always flag to work. 
      enableOnBoot = true;

      # Configure the Docker to run in rootless mode 
      rootless = mkIf cfg.rootless {
        enable = true;
        setSocketVariable = true;
      };

      # Additional daemon settings for better Netbird integration
      daemon.settings = mkIf cfg.useNetbirdDNS {
        # DNS configuration
        dns = cfg.dns;

        # # Network settings for better VPN integration
        # ip-forward = true;
        # iptables = true;

        # # Ensure Docker can route to VPN networks
        # userland-proxy = false;

        # # MTU settings for VPN compatibility
        # mtu = 1400;


        # # DNS options for better resolution
        # dns-opts = [ "use-vc" "timeout:2" "attempts:3" ];

        # # Allow Docker to use host networking when needed
        # host = [ "unix:///var/run/docker.sock" "tcp://0.0.0.0:2375" ];

        # Additional network settings for Netbird integration
        default-address-pools = [{
          base = "172.17.0.0/12";
          size = 16;
        }
          {
            base = "10.0.0.0/8"; # Additional space if needed
            size = 16;
          }];

        # DNS search domains for Netbird
        dns-search = [ "netbird.cloud" ];
      };
    };

    # Add the required system packages for Docker
    environment.systemPackages = with pkgs;
      mkMerge [
        # --- Docker ---
        [
          # Multi-container Docker orchestration
          docker-compose
        ]

        # --- Devtools ---
        (mkIf cfg.devtools [
          # Docker image layer analysis tool
          dive
          # Advanced Docker image build engine
          buildkit
          # Terminal UI for Docker management
          lazydocker
        ])
      ];
  };
}
