{
  description = "A development environment for Node.js";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs = { systems, nixpkgs, ... }@inputs:
    let
      eachSystem = f:
        nixpkgs.lib.genAttrs (import systems)
          (system: f nixpkgs.legacyPackages.${system});
    in
    {
      devShells = eachSystem (pkgs: {
        default = pkgs.mkShell {
          # Slant font https://patorjk.com/software/taag/#p=testall&f=Doom&t=NodeJS
          shellHook = ''
            echo "#
            #      _   __          __         _______
            #     / | / /___  ____/ /__      / / ___/
            #    /  |/ / __ \/ __  / _ \__  / /\__ \ 
            #   / /|  / /_/ / /_/ /  __/ /_/ /___/ / 
            #  /_/ |_/\____/\__,_/\___/\____//____/  
            #                                        
            NodeJS - $(${pkgs.nodejs-slim_22}/bin/node --version)
            Pnpm - $(${pkgs.pnpm}/bin/pnpm --version)
            " | lolcat
          '';
          nativeBuildInputs = with pkgs; [
            # aider-chat
            # claude-code


            nodejs_22
            #deno
            #bun

            # Package managers
            pnpm
            # yarn

            # Formatting
            prettierd
            # biome
            # turbo
          ];
        };
      });
    };
}
