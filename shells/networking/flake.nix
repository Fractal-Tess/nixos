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
          buildInputs = [
            pkgs.bettercap
            pkgs.iw
            pkgs.wirelesstools
            pkgs.wireshark


            pkgs.tcpdump
          ];
        };
      });
    };
}
