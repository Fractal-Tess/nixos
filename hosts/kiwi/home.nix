{
  pkgs,
  username,
  inputs,
  lib,
  ...
}:

let
  azerothSurvivors = pkgs.writeShellApplication {
    name = "azeroth-survivors";
    runtimeInputs = [ pkgs.steam-run ];
    text = ''
      GAME_ROOT="/home/${username}/Games/azeroth-survivors"
      GAME_EXE="$GAME_ROOT/windows/AzerothSurvivors/AzerothSurvivors.exe"
      export STEAM_COMPAT_CLIENT_INSTALL_PATH="/home/${username}/.local/share/Steam"
      PROTON="$STEAM_COMPAT_CLIENT_INSTALL_PATH/steamapps/common/Proton - Experimental/proton"

      if [[ ! -f "$GAME_EXE" || ! -f "$PROTON" ]]; then
        echo "Azeroth Survivors requires the installed Windows game and Steam's Proton Experimental." >&2
        exit 1
      fi

      mkdir -p "$GAME_ROOT/proton-prefix"
      export STEAM_COMPAT_DATA_PATH="$GAME_ROOT/proton-prefix"
      export SteamAppId=0
      export SteamGameId=0
      export WGPU_BACKEND=vulkan
      export PROTON_LOG=1
      export PROTON_LOG_DIR="$GAME_ROOT"
      cd "$(dirname "$GAME_EXE")"
      exec steam-run "$PROTON" run "$GAME_EXE" "$@"
    '';
  };
in
{
  #============================================================================
  # IMPORTS
  #============================================================================

  imports = [
    ../../modules/home-manager/default.nix
    ../../modules/home-manager/configs
    ../../modules/home-manager/theming.nix
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
      # agent-browser daemons detach and reparent to systemd --user, so they
      # outlive the agent that started them. With no GPU they fall back to
      # swiftshader software rendering and spin on animation frames forever.
      # Self-terminate after two idle minutes instead of leaking.
      AGENT_BROWSER_IDLE_TIMEOUT_MS = "120000";
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

  home.packages = [ azerothSurvivors ];
  xdg.desktopEntries.azeroth-survivors-native = {
    name = "Azeroth Survivors (Proton)";
    comment = "Official Windows game through Proton with Vulkan";
    exec = "${azerothSurvivors}/bin/azeroth-survivors";
    icon = "applications-games";
    terminal = false;
    categories = [ "Game" ];
  };

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

}
