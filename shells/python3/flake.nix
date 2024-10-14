{
  description = "A reproducible development environment with Python, pip, venv, and CUDA support";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      forAllSystems = function:
        nixpkgs.lib.genAttrs [
          "x86_64-linux"
          "aarch64-linux"
        ]
          (system: function (import nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
              cudaSupport = true;
            };
          }));

    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          buildInputs = with pkgs; [
            stdenv.cc.cc.lib
            libstdcxx5
            cudaPackages.cudatoolkit
            cudaPackages.cudnn
            linuxPackages.nvidia_x11
            python311
            python311Packages.pip
          ];
          shellHook = ''
            export LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.cudaPackages.cudatoolkit}/lib:${pkgs.cudaPackages.cudnn}/lib:${pkgs.linuxPackages.nvidia_x11}/lib:$LD_LIBRARY_PATH
            export CUDA_PATH=${pkgs.cudaPackages.cudatoolkit}
            export EXTRA_LDFLAGS="-L/lib -L${pkgs.linuxPackages.nvidia_x11}/lib"
            export EXTRA_CCFLAGS="-I/usr/include"
            
            # Create a virtual environment if it doesn't exist
            if [ ! -d "venv" ]; then
              python -m venv venv
            fi
            
            # Activate the virtual environment
            source venv/bin/activate
            
            # Upgrade pip in the virtual environment
            pip install --upgrade pip
            
            # Function to allow exiting the nix-shell without deactivating venv
            nix_shell_exit() {
              deactivate
              exit
            }
            
            # Alias to use the function
            alias exit=nix_shell_exit
            
            echo "Python virtual environment created and activated. Use 'pip' to install packages."
            echo "CUDA support is enabled. Make sure you have the appropriate NVIDIA drivers installed on your system."
            echo "Type 'exit' to leave the nix-shell and deactivate the virtual environment."
            
            zsh
          '';
        };
      });
    };
}
