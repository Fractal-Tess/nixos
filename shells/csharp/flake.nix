{
  description = "C# development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs = { nixpkgs, systems }:
    let eachSystem = nixpkgs.lib.genAttrs (import systems);
    in {
      devShells = eachSystem (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config = { allowUnfree = true; };
          };
        in {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              # .NET Core SDK 
              dotnet-sdk_8

              # Additional .NET tools
              # omnisharp-roslyn # C# language server

              # Supporting tools
              # nodejs # For client-side development
              # bun
              # deno
              # nodePackages.npm
              # yarn
              # pnpm

              # Debugging and runtime dependencies
              # icu # Required for globalization in .NET
              # openssl # SSL/TLS support
              # zlib # Compression library

              # Development tools
              sqlite # Local database development

              # Formatting
              prettierd
            ];

            shellHook = ''
                echo "
                 ______  __ __     ____  ____  _______   ______________
                / ____/_/ // /_   / __ \/ __ \/_  __/ | / / ____/_  __/
               / /   /_  _  __/  / / / / / / / / / /  |/ / __/   / /   
              / /___/_  _  __/  / /_/ / /_/ / / / / /|  / /___  / /    
              \____/ /_//_/    /_____/\____/ /_/ /_/ |_/_____/ /_/     
                .NET Version: $(${pkgs.dotnet-sdk_8}/bin/dotnet --version)
                "

                echo "C# with ASP.NET Core and Razor development environment activated"

                # Setup environment variables
                export DOTNET_ROOT="${pkgs.dotnet-sdk_8}/bin"
                export PATH=$PATH:$HOME/.dotnet/tools
                export ASPNETCORE_ENVIRONMENT=Development

                # Enable Razor hot reloading
                export DOTNET_WATCH_RESTART_ON_RUDE_EDIT=true

                # Cache NuGet packages in project-local directory
                # to prevent pollution of home directory
                export NUGET_PACKAGES="$PWD/.nuget/packages"
                mkdir -p "$NUGET_PACKAGES"

                # Setup temp directory for .NET
                export DOTNET_CLI_HOME="/tmp/dotnet_cli"
                mkdir -p $DOTNET_CLI_HOME
            '';
          };
        });
    };
}
