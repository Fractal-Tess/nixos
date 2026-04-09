{
  pkgs,
  username,
  lib,
  ...
}:

{
  #============================================================================
  # IMPORTS
  #============================================================================

  imports = [
    ../../modules/home-manager/default.nix
    ../../modules/home-manager/theming.nix
  ];

  #============================================================================
  # HOME MANAGER CONFIGURATION
  #============================================================================

  # Basic home configuration
  home = {
    username = username;
    homeDirectory = "/home/${username}";
    stateVersion = "25.05"; # Don't change this
    sessionVariables = {
      PNPM_HOME = "$HOME/.local/share/pnpm";
      PLAYWRIGHT_BROWSERS_PATH = "$HOME/.local/share/playwright-browsers";
      PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";
      AGENT_BROWSER_EXECUTABLE_PATH = "${pkgs.google-chrome}/bin/google-chrome";
      HF_HOME = "/mnt/vault/ai/huggingface";
    };

    activation.setupPlaywrightBrowsers = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      BROWSERS_DIR="$HOME/.local/share/playwright-browsers"
      $DRY_RUN_CMD mkdir -p "$BROWSERS_DIR"
      for dir in ${pkgs.playwright-driver.browsers}/*/; do
        name=$(basename "$dir")
        target="$BROWSERS_DIR/$name"
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
}
