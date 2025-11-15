{
  description = "Python development environment with uv";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs = { self, systems, nixpkgs, ... }:
    let
      eachSystem = f:
        nixpkgs.lib.genAttrs (import systems) (system:
          f (import nixpkgs { inherit system; }));
    in
    {
      devShells = eachSystem (pkgs: {
        default = pkgs.mkShell {
          shellHook = ''
            echo "
            #     ____        _   _             
            #    |  _ \ _   _| |_| |_ ___  _ __ 
            #    | |_) | | | | __| __/ _ \| '_ \
            #    |  __/| |_| | |_| || (_) | | | |
            #    |_|    \__, |\__|\__\___/|_| |_|
            #           |___/                     
            uv - $(${pkgs.uv}/bin/uv --version)
            " | ${pkgs.lolcat}/bin/lolcat
          '';
          LD_LIBRARY_PATH = "${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.glibc}/lib:$LD_LIBRARY_PATH";
          buildInputs = with pkgs; [
            stdenv.cc.cc.lib
            glibc
          ];
          packages = with pkgs; [
            # Python package manager
            uv

            # Python runtime (optional, uv can manage Python versions)
            python3

            # C++ standard library and runtime dependencies
            gcc
            glibc
            stdenv.cc.cc.lib
          ];
        };
      });
    };
}

