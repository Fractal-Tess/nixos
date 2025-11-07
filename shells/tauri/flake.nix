{
  description = "Tauri development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs = { nixpkgs, systems, ... }:
    let
      eachSystem = f:
        nixpkgs.lib.genAttrs (import systems)
          (system: f (import nixpkgs { inherit system; }));
    in
    {
      devShells = eachSystem (pkgs: {
        default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            pkg-config
            gobject-introspection
            cargo
            cargo-tauri # Optional, Only needed if Tauri doesn't work through the traditional way.
            nodejs # Optional, this is for if you have a js frontend
          ];

          buildInputs = with pkgs;[
            at-spi2-atk
            atkmm
            cairo
            gdk-pixbuf
            glib
            gtk3
            harfbuzz
            librsvg
            libsoup_3
            pango
            webkitgtk_4_1
            openssl
          ];
          # shellHook = "";
        };
      });
    };
}
