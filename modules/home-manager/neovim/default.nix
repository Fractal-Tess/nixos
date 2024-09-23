{ pkgs, ... }: {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    extraPackages = with pkgs;[
      nodejs_20
      yarn
      nodePackages.pnpm
      gcc

      # TODO: Move these to a devshell
      bun
      deno

      # Svelte
      nodePackages.svelte-language-server
      # Html snippets 
      emmet-language-server
      # Tailwind
      tailwindcss-language-server
      # LSP
      typescript
      typescript-language-server
      astro-language-server

      # Prettier
      prettierd
      # Rust
      rust-analyzer
      # Lua
      lua-language-server
      stylua

      # Nginx
      nginx-language-server


      # Nixos
      nil
      nixpkgs-fmt

      # This package seems to have html, css, json and eslint servers
      vscode-langservers-extracted
      # Json
      vscode-langservers-extracted
      # pkgs.nodePackages.vscode-css-languageserver-bin
      # pkgs.nodePackages.vscode-html-languageserver-bin

      # Sql
      sqls

    ];
  };
}
