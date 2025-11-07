{
  description = "Nixos go development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs = { self, systems, nixpkgs, ... }:
    let
      goVersion = 22; # Change this to update the whole stack
      overlays = [ (final: prev: { go = prev."go_1_${toString goVersion}"; }) ];
      eachSystem = f:
        nixpkgs.lib.genAttrs (import systems)
          (system: f (import nixpkgs { inherit overlays system; }));
    in
    {
      devShells = eachSystem (pkgs: {
        default = pkgs.mkShell {
          shellHook = ''
            echo "#
            #     ______      
            #    / ____/___  
            #   / / __/ __ \ 
            #  / /_/ / /_/ / 
            #  \____/\____/  
            #
            Go - $(${pkgs.go}/bin/go version)
            " | ${pkgs.lolcat}/bin/lolcat
          '';
          packages = with pkgs; [
            # go 1.20 (specified by overlay)
            go

            # goimports, godoc, etc.
            gotools

            # https://github.com/golangci/golangci-lint
            golangci-lint
          ];
        };
      });
    };
}
