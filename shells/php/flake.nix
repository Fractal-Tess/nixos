{
  description = "A Nix-flake-based PHP development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs = { nixpkgs, systems, ... }:
    let
      eachSystem = f:
        nixpkgs.lib.genAttrs (import systems)
          (system: f (import nixpkgs { inherit system; }));
    in
    {
      devShells = eachSystem (pkgs: {
        default = pkgs.mkShell {
          shellHook = ''
            echo "
             _____  _    _ _____  
            |  __ \| |  | |  __ \ 
            | |__) | |__| | |__) |
            |  ___/|  __  |  ___/ 
            | |    | |  | | |     
            |_|    |_|  |_|_|     
            PHP - $(${pkgs.php}/bin/php --version | head -n1)
            " | ${pkgs.lolcat}/bin/lolcat
          '';
          packages = with pkgs; [
            # PHP
            php
            phpPackages.composer

            # PHP Tools
            # phpPackages.phan
            # phpactor

            # Laravel
            # laravel

            # Nodejs runtime
            # bun
            # nodejs
            # yarn
            #pnpm
          ];
        };
      });
    };
}
