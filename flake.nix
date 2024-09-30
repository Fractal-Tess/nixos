{
  description = "Fractal-tess's NixOS configuration";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    polymc.url = "github:PolyMC/PolyMC";
    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      mkHost = { hostname, username }: nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs hostname username; };
        modules = [
          ./hosts/${hostname}/configuration.nix
        ];
      };
    in
    {
      nixosConfigurations = {
        vd = mkHost {
          hostname = "vd";
          username = "fractal-tess";
        };
        neo = mkHost {
          hostname = "neo";
          username = "fractal-tess";
        };
      };
    };
}
