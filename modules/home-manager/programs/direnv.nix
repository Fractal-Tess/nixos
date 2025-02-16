{ pkgs, ... }: {
  programs.direnv = {
    enable = true;
    # Faster built in implemenation of direnv
    nix-direnv.enable = true;
    # Enable direnv integration with zsh
    enableZshIntegration = true;
    # Silent direnv env loading ouput
    silent = true;
  };
}
