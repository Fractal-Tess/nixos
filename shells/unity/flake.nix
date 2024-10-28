{
  description = "Unity development environment";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
  };
  outputs =
    { systems
    , nixpkgs
    , ...
    }:
    let
      eachSystem = f:
        nixpkgs.lib.genAttrs (import systems) (
          system:
          f (import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          })
        );
    in
    {
      devShells = eachSystem (pkgs: {
        default = pkgs.mkShell {
          shellHook = ''
            zsh -c 'echo "#
            #    __  __      _ __       
            #   / / / /___  (_) /___  __
            #  / / / / __ \/ / __/ / / /
            # / /_/ / / / / / /_/ /_/ / 
            # \____/_/ /_/_/\__/\__, /  
            #                  /____/   
            " | lolcat
            zsh'
          '';
          nativeBuildInputs = with pkgs; [
            # IDE 
            jetbrains.rider

            # Unity hub
            unityhub

            # .NET SDK
            dotnet-sdk_8

            # Terminal text colorizer
            lolcat
          ];
        };
      });
    };
}
