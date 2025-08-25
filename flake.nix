{
  description = "Fractal-tess's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    polymc.url = "github:PolyMC/PolyMC";
  };

  outputs = { self, nixpkgs, polymc, sops-nix, ... }@inputs:
    let
      mkHost = { hostname, username }:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs hostname username; };
          modules = [
            ./hosts/${hostname}/configuration.nix
            {
              nixpkgs.overlays = [
                polymc.overlay
                # Overlay for Responsively App
                (import ./overlays/responsively-app.nix)
                (import ./overlays/viber.nix)
                # Overlay for Cursor
                (import ./overlays/cursor.nix)
                # (import ./overlays/ulauncher-webkitgtk.nix)
              ];
            }
          ];
        };
    in {
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
