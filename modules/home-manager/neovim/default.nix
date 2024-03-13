{ pkgs, ... }: {
  home.packages = [
    pkgs.nodejs_20
  ];
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };
}
