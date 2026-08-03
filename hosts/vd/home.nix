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
    ../../modules/home-manager/services/open-design.nix
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
      FIRECRAWL_API_URL = "http://vd.netbird.cloud:38473";
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

  systemd.user.services.shadoword-desktop = {
    Unit = {
      Description = "Shadoword desktop API client";
      After = [
        "graphical-session.target"
        "pipewire.service"
      ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.shadoword-desktop-client}/bin/shadoword-desktop";
      Restart = "on-failure";
      RestartSec = 5;
      Environment = [
        "PATH=/run/current-system/sw/bin:/etc/profiles/per-user/${username}/bin:/run/wrappers/bin"
        "WEBKIT_DISABLE_DMABUF_RENDERER=1"
      ];
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

}
