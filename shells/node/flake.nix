{
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
          shellHook = ''
            zsh;
            exit 0;
          '';
          buildInputs = with pkgs; [
            # pkgs.nodejs
            # You can set the major version of Node.js to a specific one instead
            # of the default version
            nodejs_20

            # You can choose pnpm, yarn, or none (npm).
            nodePackages.pnpm
            nodePackages.yarn
            # pkgs.nodePackages.typescript
            # pkgs.nodePackages.typescript-language-server
            nodePackages."npm-check-updates"
            nodePackages."webtorrent-cli"
            nodePackages."node2nix"
            nodePackages."nodemon"
            nodePackages."ts-node"
            nodePackages."prisma"
            nodePackages."prettier"
            prettierd
            biome
          ];
        };
      });
    };
}
