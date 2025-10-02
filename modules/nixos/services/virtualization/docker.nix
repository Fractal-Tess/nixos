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
      default = "172.20.0.0/16";
      description = "Subnet for Docker bridge network to avoid conflicts with VPN networks";
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

      # Additional daemon settings for network configuration
      daemon.settings = {
        # Network settings - use only 172.x.x.x subnets to avoid VPN conflicts
        default-address-pools = [
          {
            base = cfg.subnet;
            size = 24;
          }
          {
            base = "172.21.0.0/16";
            size = 24;
          }
          {
            base = "172.22.0.0/16";
            size = 24;
          }
          {
            base = "172.23.0.0/16";
            size = 24;
          }
          {
            base = "172.24.0.0/16";
            size = 24;
          }
          {
            base = "172.25.0.0/16";
            size = 24;
          }
          {
            base = "172.26.0.0/16";
            size = 24;
          }
          {
            base = "172.27.0.0/16";
            size = 24;
          }
          {
            base = "172.28.0.0/16";
            size = 24;
          }
          {
            base = "172.29.0.0/16";
            size = 24;
          }
          {
            base = "172.30.0.0/16";
            size = 24;
          }
          {
            base = "172.31.0.0/16";
            size = 24;
          }
        ];
        # Fixed bridge network configuration
        "fixed-cidr" = "172.20.0.0/24";
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
