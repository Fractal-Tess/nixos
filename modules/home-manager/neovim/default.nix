{ pkgs, ... }: {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    extraPackages = with pkgs;[
      # Needed fro plugins
      gcc
      deno


      # Prettier
      prettierd

      # LSPs ---

      # Svelte
      svelte-language-server

      # Html snippets 
      emmet-language-server

      # Tailwind
      tailwindcss-language-server

      # Typescript
      typescript-language-server

      # Astro
      astro-language-server

      # Docker
      docker-compose-language-service
      dockerfile-language-server-nodejs

      # Rust
      rust-analyzer

      # Lua
      lua-language-server
      stylua

      # Nginx
      nginx-language-server

      # Php
      phpactor

      # Nixos
      nixd
      nixpkgs-fmt

      # HTML/CSS/JSON/ESLint language servers extracted from vscode
      vscode-langservers-extracted

      # Sql
      sqls

      # Go
      gopls
    ];
  };
}
