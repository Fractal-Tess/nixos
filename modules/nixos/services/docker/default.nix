{ config, lib, pkgs, username, ... }:

with lib;

let cfg = config.modules.services.docker;
in {
  imports = [ ./portainer.nix ];

  options.modules.services.docker = {
    enable = mkEnableOption "Docker";
    rootless = mkEnableOption "Rootless Docker";
    nvidia = mkEnableOption "Nvidia support";
    devtools = mkEnableOption "Devtools";
    kubernetes = {
      enable = mkEnableOption "Kubernetes support";
      minikube = mkEnableOption "Minikube - Local Kubernetes cluster";
      kubectl = mkEnableOption "kubectl - Kubernetes command-line tool";
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
      package = (pkgs.docker.override (args: { buildxSupport = true; }));
      enable = true;
      # This is required for containers which are created with the 
      # --restart=always flag to work. 
      enableOnBoot = true;

      # Configure the Docker to run in rootless mode if enabled
      rootless = mkIf cfg.rootless {
        enable = true;
        setSocketVariable = true;
      };
    };

    # Add the required system packages for Docker
    environment.systemPackages = with pkgs;
      mkMerge [
        # Always install
        [
          # Run multi-container applications with Docker
          docker-compose
        ]

        (mkIf cfg.devtools [
          # Tool for exploring each layer in a docker image
          dive
          # Concurrent, cache-efficient, and Dockerfile-agnostic builder toolkit
          buildkit
          # Simple terminal UI for both docker and docker-compose
          lazydocker
        ])

        # --- Kubernetes ---

        # Helm
        (mkIf cfg.kubernetes.enable [ kubernetes-helm ])

        # Kubectl
        (mkIf cfg.kubernetes.kubectl [ kubectl ])

        # Minikube 
        (mkIf cfg.kubernetes.minikube [ minikube ])
      ];

    # Enable required services for Minikube
    virtualisation.virtualbox.host.enable =
      mkIf (cfg.kubernetes.enable && cfg.kubernetes.minikube) true;
  };
}
