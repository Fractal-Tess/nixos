{ pkgs, username, ... }:

{
  #============================================================================
  # IMPORTS
  #============================================================================

  imports = [
    ../../modules/home-manager/default.nix
    ../../modules/home-manager/configs
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
    sessionPath = [
      "$HOME/nixos/scripts"
      "$HOME/nixos/scripts/bin"
      "$HOME/nixos/scripts/hyprland"
      "$HOME/nixos/scripts/nixos"
      "$HOME/nixos/scripts/wallpaper"
      "$HOME/nixos/scripts/waybar"
      "$HOME/nixos/scripts/claude-code"
    ];
    sessionVariables = {
      PNPM_HOME = "$HOME/.local/share/pnpm";
      PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
      PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";
      AGENT_BROWSER_EXECUTABLE_PATH = "${pkgs.google-chrome}/bin/google-chrome";
    };
  };

  # Enable Home Manager self-management
  programs.home-manager.enable = true;
}
