{ config, lib, pkgs, username, ... }:

with lib;

let cfg = config.modules.services.docker;
in {
  imports = [ ./portainer.nix ./kubernetes.nix ];

  options.modules.services.docker = {
    enable = mkEnableOption "Docker";
    rootless = mkEnableOption "Rootless Docker";
    nvidia = mkEnableOption "Nvidia support";
    devtools = mkEnableOption "Devtools";
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
