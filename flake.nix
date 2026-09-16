{
  description = "Fractal-tess's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    globalprotect-openconnect.url = "github:yuezk/GlobalProtect-openconnect";

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

    asterveil = {
      url = "github:Fractal-Tess/asterveil";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    oh-my-pi-flake.url = "github:Fractal-Tess/oh-my-pi-flake";

    open-design-flake = {
      url = "github:Fractal-Tess/open-design-flake";
    };

    responsively-flake.url = "github:Fractal-Tess/responsively-flake";

    clip-sync = {
      url = "github:Fractal-Tess/clip-sync";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    shadoword = {
      url = "github:Fractal-Tess/shadoword";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    scorch = {
      url = "github:Fractal-Tess/scorch";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    gitadel = {
      url = "github:Fractal-Tess/gitadel";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      polymc,
      sops-nix,
      nix4nvchad,

      ...
    }@inputs:
    let
      mkHost =
        { hostname, username }:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs hostname username; };
          modules = [
            ./hosts/${hostname}/configuration.nix
            {
              nixpkgs.config.allowBroken = true;
              nixpkgs.overlays = [
                (final: prev: {
                  qt6Packages = prev.qt6Packages.overrideScope (
                    _final: _prev: {
                      extra-cmake-modules = final.kdePackages.extra-cmake-modules;
                    }
                  );
                })
                polymc.overlay
                (import ./overlays/cursor.nix)
                (import ./overlays/terax.nix)
                (import ./overlays/vibe-kanban.nix)
                (import ./overlays/kimi-cli)
                (final: prev: {
                  # openldap's syncrepl test is flaky on this pinned nixpkgs revision
                  # and blocks transitive consumers like bottles during local builds.
                  openldap = prev.openldap.overrideAttrs (_: {
                    doCheck = false;
                  });
                })
                (import ./overlays/claude-code)
                (import ./overlays/tws.nix)
                (import ./overlays/vllm.nix)
                (import ./overlays/llama-cpp.nix)
                (import ./overlays/ollama.nix)
                (import ./overlays/uefi-firmware-parser.nix)
                (import ./overlays/viber.nix)
                (import ./overlays/wfuzz-fix.nix)
                (import ./overlays/cliproxyapi.nix)
              ];
            }
          ];
        };
    in
    {
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt;
      checks.x86_64-linux.application-interfaces = import ./checks/application-interfaces.nix {
        inherit inputs;
      };
      templates.program-module = {
        path = ./templates/program-module;
        description = "A runnable program flake with matching NixOS and Home Manager modules";
      };

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
