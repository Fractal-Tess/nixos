{ pkgs, ... }: {
  home.packages = with pkgs ;[
    # Nodejs
    nodejs_20
    # Svelte
    nodePackages.svelte-language-server
    # Html snippets 
    emmet-language-server
    # Tailwind
    tailwindcss-language-server
    # Typescript
    nodePackages.typescript-language-server
    # Prettier
    prettierd
    nodePackages.prettier
    # Rust
    rust-analyzer
    # Lua
    lua-language-server
    stylua
    # Nixos
    nil
    nixpkgs-fmt
    # This package seems to have html, css, json and eslint servers
    vscode-langservers-extracted
    # pkgs.nodePackages.vscode-css-languageserver-bin
    # pkgs.nodePackages.vscode-html-languageserver-bin
  ];
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };
}
