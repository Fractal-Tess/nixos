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

    responsively = {
      url = "github:Fractal-Tess/responsively-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, responsively, polymc, ... }@inputs:
    let
      mkHost = { hostname, username }: nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs hostname username; };
        modules = [
          ./hosts/${hostname}/configuration.nix
          {
            nixpkgs.overlays = [
              polymc.overlay
              responsively.overlay."x86_64-linux" # Adjust system here
            ];
          }
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
