{
  description = "A development environment for C/C++ using clang";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs = { self, systems, nixpkgs, ... }:
    let
      clangVersion = 19; # Change this to update the whole stack
      overlays = [
        (final: prev: {
          llvm = prev."llvmPackages_${toString clangVersion}";
          clang = prev."clang_${toString clangVersion}";
        })
      ];
      eachSystem = f:
        nixpkgs.lib.genAttrs (import systems)
          (system: f (import nixpkgs { inherit overlays system; }));
    in
    {
      devShells = eachSystem (pkgs: {
        default = pkgs.mkShell {
          shellHook = ''
            echo "
                 ______
                / ____/
               / /     
              / /___   
              \____/   

              clang version: $(${pkgs.clang}/bin/clang --version | head -n 1)
            " | ${pkgs.lolcat}/bin/lolcat;
            zsh;
            exit 0;
          '';
          packages = with pkgs;
            [
              clang
              # Build tools
              # gnumake
              # cmake
              # bear

              # Debuggers
              # llvm.lldb
              # gdb

              # Fix headers not found
              # clang-tools

              # lsp and compiler
              # llvm.libstdcxxClang

              # other tools
              # cppcheck
              # llvm.libllvm
              # valgrind

              # stdlib for cpp
              # llvm.libcxx

              # libs
              # glm
              # SDL2
              # SDL2_gfx
            ];
        };
      });
    };
}

