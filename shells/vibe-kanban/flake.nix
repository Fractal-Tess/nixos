{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    systems.url = "github:nix-systems/default";
  };
  outputs = { self, systems, nixpkgs, ... }@inputs:
    let
      eachSystem = f:
        nixpkgs.lib.genAttrs (import systems) (system:
          f (import nixpkgs {
            inherit system;
            overlays = [ inputs.rust-overlay.overlays.default ];
          }));
    in {
      devShells = eachSystem (pkgs: {
        default = pkgs.mkShell {
          nativeBuildInputs = with pkgs;
            [
              # Rust toolchain with cargo, rustc, etc.
              (rust-bin.stable.latest.default.override {
                extensions =
                  [ "rust-analyzer" "clippy" "rustfmt" "rust-src" "rust-docs" ];
                targets = [ "x86_64-unknown-linux-musl" ];
              })

              # Node.js and package managers
              nodejs_22
              pnpm
              bun

              # Build tools
              pkg-config
              openssl

              # Development tools
              git
            ];

          RUST_SRC_PATH =
            "${pkgs.rust-bin.stable.latest.rust-src}/lib/rustlib/src/rust/library";

          # Set up environment for development
          shellHook = ''
            echo "🚀 Vibe-Kanban development environment ready!"
            echo "   Rust: $(rustc --version)"
            echo "   Node: $(node --version)"
            echo "   pnpm: $(pnpm --version)"
            echo "   Bun:  $(bun --version)"
          '';
        };
      });
    };
}
