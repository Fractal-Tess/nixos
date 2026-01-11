{ pkgs, ... }:
{
  programs.direnv = {
    enable = true;
    # Faster built in implemenation of direnv
    nix-direnv.enable = true;
    # Enable direnv integration with zsh
    enableFishIntegration = true;
    # Silent direnv env loading ouput
    silent = true;
  };
}
