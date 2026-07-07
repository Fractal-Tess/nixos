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

    nix-matlab = {
      url = "gitlab:doronbehar/nix-matlab";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Pentesting tools
    pwndbg = {
      url = "github:pwndbg/pwndbg/2024.08.29";
    };

    nixpkgs-burpsuite = {
      url = "github:NixOS/nixpkgs/e6f23dc08d3624daab7094b701aa3954923c6bbb";
    };

    nixpkgs-openclaw = {
      url = "github:chrisportela/nixpkgs/cp/add-moltbot";
    };

    nix-openclaw = {
      url = "github:openclaw/nix-openclaw";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    asterveil = {
      url = "github:Fractal-Tess/asterveil";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    t3code-nix = {
      url = "github:Sawrz/t3code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    comfyui-nix = {
      url = "github:utensils/comfyui-nix";
    };

    shapeshifter = {
      url = "github:Fractal-Tess/shapeshifter";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
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

      nix-matlab,
      ...
    }@inputs:
    let
      mkHost =
        { hostname, username }:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs hostname username; };
          modules = [
            inputs.hermes-agent.nixosModules.default
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
                nix-matlab.overlay
                (import ./overlays/responsively-app.nix)
                (import ./overlays/cursor.nix)
                (import ./overlays/terax.nix)
                (import ./overlays/vibe-kanban.nix)
                (import ./overlays/kimi-cli)
                (import ./overlays/netbird-fix.nix)
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
                (import ./overlays/uefi-firmware-parser.nix)
                (import ./overlays/viber.nix)
                inputs.t3code-nix.overlays.default
                inputs.shapeshifter.overlays.default
                inputs.asterveil.overlays.default
              ];
            }
          ];
        };
    in
    {
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt;

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
