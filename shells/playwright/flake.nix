{
  description = "A development environment for Playwright testing on NixOS";

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
          packages = with pkgs; [
            nodejs_22
            pnpm
            playwright-driver.browsers
          ];

          shellHook = ''
            export PLAYWRIGHT_BROWSERS_PATH=${pkgs.playwright-driver.browsers}
            export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true
            
            echo "
             ____  _                           _       _     _   
            |  _ \| | __ _ _   ___      ___ __(_) __ _| |__ | |_ 
            | |_) | |/ _\` | | | \ \ /\ / / '__| |/ _\` | '_ \| __|
            |  __/| | (_| | |_| |\ V  V /| |  | | (_| | | | | |_ 
            |_|   |_|\__,_|\__, | \_/\_/ |_|  |_|\__, |_| |_|\__|
                           |___/                 |___/           
            
            Playwright browsers: ${pkgs.playwright-driver.browsers}
            Node.js: $(node --version)
            
            NOTE: Use 'playwright-core' instead of 'playwright' in package.json
                  to avoid downloading bundled browsers.
                  
            For npm projects:  npm install playwright-core @playwright/test
            For pnpm projects: pnpm add playwright-core @playwright/test
            " | ${pkgs.lolcat}/bin/lolcat
          '';
        };
      });
    };
}
