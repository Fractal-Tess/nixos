{ config, lib, pkgs, ... }:

with lib;

# https://nixos.wiki/wiki/Kubernetes
let cfg = config.modules.services.kubernetes;
in {
  options.modules.services.kubernetes = {
    enable = mkEnableOption "Kubernetes support";
  };

  config = mkIf cfg.enable {
    # Install Kubernetes and related tools
    environment.systemPackages = with pkgs; [
      kubernetes
      kubectl
      kubernetes-helm
      minikube
    ];

    # Enable VirtualBox host support for Minikube
    virtualisation.virtualbox.host.enable = true;

    # Example: Enable kubelet and basic cluster (see wiki for more advanced usage)
    # services.kubernetes = {
    #   roles = [ "master" ];
    #   kubelet.extraOpts = "--fail-swap-on=false";
    # };
  };
}
