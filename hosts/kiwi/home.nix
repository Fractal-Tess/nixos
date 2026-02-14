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
      PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
      PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";
      AGENT_BROWSER_EXECUTABLE_PATH = "/run/current-system/sw/bin/chromium";
    };
  };

  # Enable Home Manager self-management
  programs.home-manager.enable = true;

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
