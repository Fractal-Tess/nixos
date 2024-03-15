{ pkgs, ... }: {
  home.packages = [
    pkgs.nodejs_20
    pkgs.nodePackages.svelte-language-server
    pkgs.emmet-language-server
    pkgs.tailwindcss-language-server
    pkgs.nodePackages.typescript-language-server
    pkgs.prettierd
    pkgs.nodePackages.prettier
    pkgs.nodePackages.vscode-html-languageserver-bin
  ];
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };
}
