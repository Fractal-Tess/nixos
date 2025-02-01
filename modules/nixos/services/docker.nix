{ config, lib, username, pkgs, ... }:

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

    environment.systemPackages = with pkgs;
      (optionals cfg.devtools [ lazydocker dive htop ]) ++
      (optionals cfg.kubernetes.enable (
        [ kubernetes-helm ] ++
        (optionals cfg.kubernetes.kubectl [ kubectl ]) ++
        (optionals cfg.kubernetes.minikube [ minikube ])
      ));

    # Enable required services for Minikube
    virtualisation.virtualbox.host.enable = mkIf (cfg.kubernetes.enable && cfg.kubernetes.minikube) {
      enable = true;
    };
  };
}
