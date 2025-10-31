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

    nix4nvchad = {
      url = "github:nix-community/nix4nvchad";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    polymc.url = "github:PolyMC/PolyMC";
  };

  outputs = { self, nixpkgs, polymc, sops-nix, nix4nvchad, ... }@inputs:
    let
      mkHost = { hostname, username }:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs hostname username; };
          modules = [
            ./hosts/${hostname}/configuration.nix
            {
              nixpkgs.config.allowBroken = true;
              nixpkgs.overlays = [
                polymc.overlay
                (import ./overlays/responsively-app.nix)
                (import ./overlays/viber.nix)
                (import ./overlays/cursor.nix)
                (import ./overlays/claude-flow)
                # Fix for renamed packages
                (final: prev: {
                  glxinfo = prev.mesa-demos;
                  poppler_utils = prev.poppler-utils;
                  protonup = prev.protonup-ng;
                })
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
        kiwi = mkHost {
          hostname = "kiwi";
          username = "fractal-tess";
        };
      };
    };
}
