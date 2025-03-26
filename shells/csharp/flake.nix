{
  description = "C# development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs = { self, systems, nixpkgs, ... }:
    let
      dotnetVersion = 8; # Change this to update the whole stack
      overlays = [
        (final: prev: {
          dotnet-sdk = prev."dotnet-sdk_${toString dotnetVersion}";
        })
      ];
      eachSystem = f:
        nixpkgs.lib.genAttrs (import systems) (system:
          f (import nixpkgs {
            inherit overlays system;
            config.allowUnfree = true;
          }));
    in
    {
      devShells = eachSystem (pkgs: {
        default = pkgs.mkShell {
          shellHook = ''
            echo "
                 ______  __ __     ____  ____  _______   ______________
                / ____/_/ // /_   / __ \/ __ \/_  __/ | / / ____/_  __/
               / /   /_  _  __/  / / / / / / / / / /  |/ / __/   / /   
              / /___/_  _  __/  / /_/ / /_/ / / / / /|  / /___  / /    
              \____/ /_//_/    /_____/\____/ /_/ /_/ |_/_____/ /_/     

            .NET Version: $(${pkgs.dotnet-sdk}/bin/dotnet --version)
            " | ${pkgs.lolcat}/bin/lolcat

            # Setup environment variables
            export DOTNET_ROOT="${pkgs.dotnet-sdk}/bin"
            export PATH=$PATH:$HOME/.dotnet/tools
            export ASPNETCORE_ENVIRONMENT=Development

            # Enable Razor hot reloading
            export DOTNET_WATCH_RESTART_ON_RUDE_EDIT=true

            # Cache NuGet packages in project-local directory
            export NUGET_PACKAGES="$PWD/.nuget/packages"
            mkdir -p "$NUGET_PACKAGES"

            # Setup temp directory for .NET
            export DOTNET_CLI_HOME="/tmp/dotnet_cli"
            mkdir -p $DOTNET_CLI_HOME

            # Check if zsh is installed and use it as the default shell
            if command -v zsh &> /dev/null; then
              zsh;
              exit 0;
            fi
          '';

          packages = with pkgs; [
            # .NET SDK (specified by overlay)
            dotnet-sdk

            # Development tools
            sqlite # Local database development

            # Formatting and tools
            prettierd
            lolcat

            # Additional tools (commented out by default)
            # omnisharp-roslyn # C# language server
            # nodejs # For client-side development
            # bun
            # deno
            # nodePackages.npm
            # yarn
            # pnpm
          ];
        };
      });
    };
}
