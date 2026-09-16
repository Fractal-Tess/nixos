{
  description = "A program flake with matching NixOS and Home Manager modules";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (system: {
        hello = nixpkgs.legacyPackages.${system}.hello;
        default = self.packages.${system}.hello;
      });
      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = nixpkgs.lib.getExe self.packages.${system}.hello;
          meta.description = "Print a greeting";
        };
      });
      nixosModules.default = import ./modules/nixos.nix { flake = self; };
      homeManagerModules.default = import ./modules/home-manager.nix { flake = self; };
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);
    };
}
