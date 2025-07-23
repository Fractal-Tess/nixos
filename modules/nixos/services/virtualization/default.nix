{ ... }: {
  imports = [
    ./docker.nix
    ./firecracker.nix
    ./kubernetes.nix
    ./podman.nix

    ./containers/portainer.nix
    ./containers/jellyfin.nix
  ];
}
