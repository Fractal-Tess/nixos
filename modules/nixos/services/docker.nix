{ config, lib, username, pkgs, environment, ... }:

with lib;

let
  cfg = config.modules.services.docker;
in
{
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

  config = mkIf cfg.enable {
    users.extraGroups.docker.members = [ username ];

    # GPU Drivers (Nvidia) for containers
    hardware.nvidia-container-toolkit.enable = cfg.nvidia;

    virtualisation.docker = {
      package = (pkgs.docker.override (args: { buildxSupport = true; }));
      enable = true;
      rootless = mkIf cfg.rootless {
        enable = true;
        setSocketVariable = true;
      };
    };

    # Kubernetes related configuration
    environment.systemPackages = mkIf cfg.kubernetes.enable (
      [ pkgs.kubernetes-helm ] ++
      (optionals cfg.kubernetes.kubectl [ pkgs.kubectl ]) ++
      (optionals cfg.kubernetes.minikube [ pkgs.minikube ])
    );

    environment.systemPackages = mkIf cfg.devtools (with pkgs; [
      lazydocker
      dive
    ]);

    # Enable required services for Minikube
    virtualisation.virtualbox.host.enable = mkIf (cfg.kubernetes.enable && cfg.kubernetes.minikube) {
      enable = true;
    };
  };


}
