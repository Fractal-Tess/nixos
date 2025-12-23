{ pkgs, config, inputs, ... }: {
  imports = [
    ./programs/direnv.nix
    ./programs/zoxide.nix
    ./programs/yt-dlp.nix
    ./programs/nextcloud.nix
    ./programs/git.nix
    ./programs/kitty.nix
    ./programs/neovim.nix
    ./programs/eza.nix
    ./programs/bat.nix
    ./programs/flare.nix
  ];
}

