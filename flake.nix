{
  description = "Fractal-tess's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    sops-nix = {
      url = "github:Mic92/sops-nix/master";
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

    polymc = {
      url = "github:PolyMC/PolyMC";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flare = {
      url = "github:ByteAtATime/flare/feat/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-matlab = {
      url = "gitlab:doronbehar/nix-matlab";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-openclaw = {
      url = "github:chrisportela/nixpkgs/cp/add-moltbot";
    };
  };

  outputs = { self, nixpkgs, polymc, sops-nix, nix4nvchad, flare, nix-matlab, ... }@inputs:
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
                nix-matlab.overlay
                (import ./overlays/responsively-app.nix)
                (import ./overlays/cursor.nix)
                (import ./overlays/handy.nix)
                (final: prev: {
                  openclaw = (import inputs.nixpkgs-openclaw {
                    system = final.system;
                    config = {
                      allowUnfree = true;
                      permittedInsecurePackages = [ "openclaw-2026.1.30" ];
                    };
                  }).openclaw;
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
