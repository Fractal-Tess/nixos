{
  description = "A minimal Java development environment";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
  };
  outputs = { systems, nixpkgs, ... } @ inputs:
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
            echo "#
            #
            #        __                 
            #       / /___ __   ______ _
            #  __  / / __ `/ | / / __ `/
            # / /_/ / /_/ /| |/ / /_/ / 
            # \____/\__,_/ |___/\__,_/  
            #                           
            #
            Java - $(${pkgs.jdk}/bin/java --version | head -n 1)
            " | ${pkgs.lolcat}/bin/lolcat
          '';
          nativeBuildInputs = with pkgs; [
            jdk
          ];
        };
      });
    };
}
