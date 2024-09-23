{
  description = "C/C++ Clang 18 environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:

    let

      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f rec {
        pkgs = nixpkgs.legacyPackages.${system};
        llvm = pkgs.llvmPackages_18;
      });

    in
    {
      devShells = forEachSupportedSystem
        ({ pkgs, llvm }: {
          default = pkgs.mkShell.override
            {
              stdenv = pkgs.clangStdenv;
            }
            rec
            {
              # TODO: Remove this shellHook - This here is bad because it assumes that zsh is installed and is prefered 
              shellHook = ''
                zsh
                exit
              '';
              packages = with pkgs; [
                # builder
                gnumake
                cmake
                bear

                # debugger
                llvm.lldb
                gdb

                # fix headers not found
                clang-tools

                # lsp and compiler
                llvm.libstdcxxClang

                # other tools
                cppcheck
                llvm.libllvm
                valgrind

                # stdlib for cpp
                llvm.libcxx

                # libs
                glm
                SDL2
                SDL2_gfx
              ];
            };
        });
    };
}
