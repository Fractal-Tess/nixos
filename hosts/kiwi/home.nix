{
  pkgs,
  username,
  inputs,
  lib,
  ...
}:

{
  #============================================================================
  # IMPORTS
  #============================================================================

  imports = [
    ../../modules/home-manager/default.nix
    ../../modules/home-manager/configs
    ../../modules/home-manager/theming.nix
    inputs.nix4nvchad.homeManagerModule
  ];

  #============================================================================
  # HOME MANAGER CONFIGURATION
  #============================================================================

  # Basic home configuration
  home = {
    username = username;
    homeDirectory = "/home/${username}";
    stateVersion = "24.05"; # Don't change this
    sessionVariables = {
      # Point to a writable directory (symlinks into the Nix store).
      # playwright-mcp creates temp profile dirs (mcp-chrome-XXXXX) inside
      # PLAYWRIGHT_BROWSERS_PATH, which would fail if it pointed directly at
      # the read-only Nix store.
      PLAYWRIGHT_BROWSERS_PATH = "$HOME/.local/share/playwright-browsers";
      PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";
      AGENT_BROWSER_EXECUTABLE_PATH = "/run/current-system/sw/bin/chromium";
    };

    activation.setupPlaywrightBrowsers = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      BROWSERS_DIR="$HOME/.local/share/playwright-browsers"
      $DRY_RUN_CMD mkdir -p "$BROWSERS_DIR"
      for dir in ${pkgs.playwright-driver.browsers}/*/; do
        name=$(basename "$dir")
        target="$BROWSERS_DIR/$name"
        # Remove stale symlink pointing to old store path
        if [ -L "$target" ] && [ "$(readlink "$target")" != "$dir" ]; then
          $DRY_RUN_CMD rm "$target"
        fi
        if [ ! -e "$target" ]; then
          $DRY_RUN_CMD ln -s "$dir" "$target"
        fi
      done
    '';
  };

  # Enable Home Manager self-management
  programs.home-manager.enable = true;

  # Laptop battery monitoring
  modules.services.battery-check.enable = false;

  #============================================================================
  # SHELL CONFIGURATION
  #============================================================================

  # Add custom scripts to PATH
  home.sessionPath = [
    "/home/${username}/nixos/scripts"
  ];

  # Disable default neovim to avoid conflict with NvChad
  programs.neovim.enable = lib.mkForce false;

  # Enable NvChad
  programs.nvchad = {
    enable = true;
    extraPackages = with pkgs; [
      # Language servers
    ];
    backup = true;
  };
}
