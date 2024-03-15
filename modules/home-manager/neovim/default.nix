{ pkgs, ... }: {
  home.packages = [
    pkgs.nodejs_20
    pkgs.nodePackages.svelte-language-server
    pkgs.emmet-language-server

  ];
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };
}
