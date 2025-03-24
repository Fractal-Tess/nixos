{
  description = "C/C++ Clang 18 environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs = { self, nixpkgs, systems }:
    let eachSystem = nixpkgs.lib.genAttrs (import systems);
    in {
      devShells = eachSystem (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config = { allowUnfree = true; };
          };
          llvm = pkgs.llvmPackages_19; # Change this to update the whole stack
          clang = pkgs.clang_19;
        in {
          default = pkgs.mkShell {
            shellHook = ''
              echo "
                 ______
                / ____/
               / /     
              / /___   
              \____/   
              clang version: $(${clang}/bin/clang --version | head -n 1)
              " | ${pkgs.lolcat}/bin/lolcat
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
