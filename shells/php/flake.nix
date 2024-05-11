{
  description = "A Nix-flake-based PHP development environment";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.*.tar.gz";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs { inherit system; };
      });
    in
    {
      devShells = forEachSupportedSystem ({ pkgs }: {
        default = pkgs.mkShell {
          shellHook = ''
            zsh;
            exit 0;
          '';
          packages = with pkgs; [
            php
            phpPackages.composer
            phpPackages.php-cs-fixer
            phpPackages.phan
            phpactor
          ];

        };
      });
    };
}
