{ ... }:
{
  imports = [
    ./programs/direnv.nix
    ./programs/nextcloud.nix
    ./programs/git.nix
    ./programs/fish.nix
    ./programs/bat.nix
    ./programs/yazi.nix
    ./services/battery-check.nix
  ];
}
