{ config, lib, pkgs, username, ... }:

with lib;

let cfg = config.modules.services.virtualization.docker;
in {
  options.modules.services.virtualization.docker = {
    enable = mkEnableOption "Docker";
    rootless = mkEnableOption "Rootless Docker";
    nvidia = mkEnableOption "Nvidia support";
    devtools = mkEnableOption "Devtools";

    subnet = mkOption {
      type = types.str;
      default = "172.20.0.1/16";
      description =
        "Gateway for Docker bridge network to avoid conflicts with VPN networks";
    };

    addressPools = mkOption {
      type = types.listOf (types.attrsOf types.anything);
      default = [{
        base = "172.21.0.0/16";
        size = 24;
      }];
      description =
        "Default address pools for Docker networks to avoid VPN conflicts";
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

      # Common daemon settings for both regular and rootless Docker
      daemon.settings = mkIf (!cfg.rootless) {
        bip = cfg.subnet;
        # Network settings - use only 172.x.x.x subnets to avoid VPN conflicts
        # Explicitly exclude 10.x.x.x networks to prevent VPN conflicts
        default-address-pools = cfg.addressPools;
        # Use VPN DNS servers directly for .int domain resolution
        # 10.1.111.17 and 10.1.111.19 are the DNS servers from tun0 VPN interface
        # Fallback to public DNS if VPN DNS is unavailable
        dns = [ "10.1.111.17" "10.1.111.19" "1.1.1.1" "8.8.8.8" ];
        "dns-search" = [ "int" "netbird.cloud" ];
        # Increase DNS timeout to handle slower VPN DNS resolution
        "dns-opts" = [ "timeout:5" "attempts:3" ];
      };

      # Configure the Docker to run in rootless mode
      rootless = mkIf cfg.rootless {
        enable = true;
        setSocketVariable = true;
        daemon.settings = {
          bip = cfg.subnet;
          # Network settings - use only 172.x.x.x subnets to avoid VPN conflicts
          # Explicitly exclude 10.x.x.x networks to prevent VPN conflicts
          default-address-pools = cfg.addressPools;
          # Use VPN DNS servers directly for .int domain resolution
          # 10.1.111.17 and 10.1.111.19 are the DNS servers from tun0 VPN interface
          # Fallback to public DNS if VPN DNS is unavailable
          dns = [ "10.1.111.17" "10.1.111.19" "1.1.1.1" "8.8.8.8" ];
          "dns-search" = [ "int" "netbird.cloud" ];
          # Increase DNS timeout to handle slower VPN DNS resolution
          "dns-opts" = [ "timeout:5" "attempts:3" ];
        };
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
