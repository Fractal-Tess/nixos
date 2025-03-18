{
  description = "A development environment for Node.js";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs = { systems, nixpkgs, ... }:
    let
      nodeVersion = 22; # Change this to update the whole stack
      overlays = [ (final: prev: { nodejs = prev."nodejs-slim_${toString nodeVersion}"; }) ];
      eachSystem = f:
        nixpkgs.lib.genAttrs (import systems) (
          system:
          f (import nixpkgs { inherit overlays system; })
        );
    in
    {
      devShells = eachSystem (pkgs: {
        default = pkgs.mkShell {
          shellHook = ''
            echo "
                  _   __          __         _______
                 / | / /___  ____/ /__      / / ___/
                /  |/ / __ \/ __  / _ \__  / /\__ \ 
               / /|  / /_/ / /_/ /  __/ /_/ /___/ / 
              /_/ |_/\____/\__,_/\___/\____//____/  
                                                    
            NodeJS - $(${pkgs.nodejs}/bin/node --version)
            Pnpm - $(${pkgs.pnpm}/bin/pnpm --version)
            " | ${pkgs.lolcat}/bin/lolcat
          '';
          packages = with pkgs; [

            # Node.js (specified by overlay)
            nodejs

            # bun
            # deno

            # Package managers
            pnpm
            # yarn


            # Formatting
            prettierd
            # biome
            # eslint
            # npkill
          ];
        };
      });
    };
}
