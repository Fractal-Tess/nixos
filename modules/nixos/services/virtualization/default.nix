{ ... }:
{
  imports = [
    ./docker.nix
    ./firecracker.nix
    ./kubernetes.nix
    ./podman.nix
    ./virtualbox.nix
  ];
}
