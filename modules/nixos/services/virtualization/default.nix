{ ... }: {
  imports = [
    ./docker.nix
    ./firecracker.nix
    ./kubernetes.nix
    ./podman.nix

    # Import backup utilities first so they're available to container modules
    ./containers/backup-utils.nix
    ./containers/portainer.nix
    ./containers/jellyfin.nix
    ./containers/netdata.nix
  ];
}
