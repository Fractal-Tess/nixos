{ ... }: {
  imports = [
    ./docker.nix
    ./firecracker.nix
    ./kubernetes.nix
    ./podman.nix
    ./containers/portainer.nix
    ./containers/jellyfin.nix
    ./containers/netdata.nix
    ./containers/jackett.nix
    ./containers/qbittorrent.nix
    ./containers/sonarr.nix
  ];
}
