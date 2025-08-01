{
  description = "Tauri development shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs = { nixpkgs, systems, ... }@inputs:
    let
      eachSystem = f:
        nixpkgs.lib.genAttrs (import systems)
        (system: f nixpkgs.legacyPackages.${system});

      libraries = pkgs:
        with pkgs; [
          webkitgtk_4_1
          gtk3
          cairo
          gdk-pixbuf
          glib
          dbus
          openssl_3
          librsvg
          mold
        ];

      packages = pkgs:
        with pkgs; [
          curl
          wget
          pkg-config
          dbus
          openssl_3
          glib
          gtk3
          webkitgtk_4_1
          librsvg
          clang
          mold
          cargo
          rustc
          rustfmt

          # Node
          nodejs_22
          pnpm
          yarn
          prettierd
          npkill
          lolcat
        ];
    in {
      devShells = eachSystem (pkgs: {
        default = pkgs.mkShell {
          buildInputs = packages pkgs;

          shellHook = ''
            echo "#
            #  ______                  _ 
            # /_  __/___ ___  _______(_)
            #  / / / __ `/ / / / ___/ / 
            # / / / /_/ / /_/ / /  / /  
            #/_/  \__,_/\__,_/_/  /_/   
            #
            Tauri Development Environment
            NodeJS - $(${pkgs.nodejs_22}/bin/node --version)
            Rustc - $(${pkgs.rustc}/bin/rustc --version)
            " | lolcat


            export LD_LIBRARY_PATH=${
              pkgs.lib.makeLibraryPath (libraries pkgs)
            }:$LD_LIBRARY_PATH
            export XDG_DATA_DIRS=${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:$XDG_DATA_DIRS
          '';
        };
      });
    };
}
