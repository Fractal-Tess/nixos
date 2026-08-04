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
    ../../modules/home-manager/services/open-design.nix
    inputs.nix4nvchad.homeManagerModules.default
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
      FIRECRAWL_API_URL = "http://vd.netbird.cloud:38473";
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
  modules.services.battery-check.enable = true;

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

  systemd.user.services.shadoword-desktop = {
    Unit = {
      Description = "Shadoword desktop transcription client";
      After = [
        "graphical-session.target"
        "pipewire.service"
      ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${
        inputs.shadoword.packages.${pkgs.system}.shadoword-desktop-client
      }/bin/shadoword-desktop";
      Restart = "on-failure";
      RestartSec = 5;
      Environment = [
        "PATH=/run/current-system/sw/bin:/etc/profiles/per-user/${username}/bin:/run/wrappers/bin"
        # Keep WebKitGTK on the backend that preserves Tauri's scale and SVG
        # strokes under Wayland compositors.
        "GDK_BACKEND=x11"
        "WEBKIT_DISABLE_DMABUF_RENDERER=1"
      ];
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
