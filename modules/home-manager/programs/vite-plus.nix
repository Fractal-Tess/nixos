{ inputs, ... }:

{
  imports = [ inputs.vite-plus-flake.homeManagerModules.default ];

  programs.vite-plus.enable = true;
}
