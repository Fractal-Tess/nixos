{
  config,
  lib,
  pkgs,
  username,
  ...
}:

with lib;

# https://nixos.wiki/wiki/Kubernetes
let
  cfg = config.modules.services.virtualization.kubernetes;
in
{
  options.modules.services.virtualization.kubernetes = {
    enable = mkEnableOption "Kubernetes support";
  };

  config = mkIf cfg.enable {
    # Enable k3s - lightweight Kubernetes distribution
    services.k3s = {
      enable = true;
      role = "server";
      extraFlags = [
        "--disable=traefik" # We'll use our own ingress controller
        "--tls-san=infisical.fractal-tess.xyz"
      ];
    };

    # Install Kubernetes and related tools
    environment.systemPackages = with pkgs; [
      kubernetes
      kubectl
      kubernetes-helm
      k9s
      kubeshark
      certmgr
    ];

    # Ensure kubeconfig is available to user
    systemd.tmpfiles.rules = [
      "L+ /home/${username}/.kube/config - - - - /etc/rancher/k3s/k3s.yaml"
    ];

    # Add user to k3s group for kubectl access without sudo
    users.groups.k3s = { };
    users.users.${username}.extraGroups = [ "k3s" ];

    # Required firewall ports for k3s
    networking.firewall.allowedTCPPorts = [
      6443 # Kubernetes API server
      10250 # Kubelet metrics
      2379 # etcd client requests
      2380 # etcd peer communication
      8472 # Flannel VXLAN
      80 # HTTP for ingress
      443 # HTTPS for ingress
    ];
    networking.firewall.allowedUDPPorts = [
      8472 # Flannel VXLAN
    ];

    # Enable virtualbox for Minikube if needed (optional)
    virtualisation.virtualbox.host.enable = mkDefault false;

    # Post-installation: Install ingress-nginx and cert-manager after k3s is ready
    systemd.services.k3s-post-setup = {
      description = "Install ingress-nginx and cert-manager after k3s is ready";
      after = [ "k3s.service" ];
      requires = [ "k3s.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "root";
        ExecStart = pkgs.writeShellScript "k3s-post-setup" ''
          export PATH="${pkgs.kubectl}/bin:${pkgs.kubernetes-helm}/bin:$PATH"
          export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

          # Wait for k3s to be ready
          echo "Waiting for k3s to be ready..."
          until kubectl cluster-info &>/dev/null; do
            sleep 2
          done

          # Install ingress-nginx
          if ! kubectl get namespace ingress-nginx &>/dev/null 2>&1; then
            echo "Installing ingress-nginx..."
            kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.6/deploy/static/provider/cloud/deploy.yaml
          fi

          # Install cert-manager
          if ! kubectl get namespace cert-manager &>/dev/null 2>&1; then
            echo "Installing cert-manager..."
            kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.yaml
          fi

          echo "k3s post-setup complete"
        '';
      };
    };
  };
}
