{
  description = "A development environment for Node.js";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs =
    { systems
    , nixpkgs
    , ...
    } @ inputs:
    let
      eachSystem = f:
        nixpkgs.lib.genAttrs (import systems) (
          system:
          f nixpkgs.legacyPackages.${system}
        );
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
            NodeJS - $(${pkgs.nodejs_20}/bin/node --version)
            Npm - $(${pkgs.nodejs_20}/bin/npm --version)
            Pnpm - $(${pkgs.pnpm}/bin/pnpm --version)
            Yarn - $(${pkgs.yarn}/bin/yarn --version)
            " | lolcat
          '';
          nativeBuildInputs = with pkgs; [
            nodejs_20

            # Package managers
            pnpm
            yarn

            # Formatting
            prettierd

            # Additional tools
            nodePackages."npm-check-updates"
            npkill

          ];
        };
      });
    };
}
