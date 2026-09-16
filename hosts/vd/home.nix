{
  pkgs,
  username,
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
      AGENT_BROWSER_EXECUTABLE_PATH = "${pkgs.google-chrome}/bin/google-chrome";
      OD_DAEMON_URL = "http://127.0.0.1:38471";
      HF_HOME = "/mnt/vault/ai/huggingface";
    };
  };

  # Enable Home Manager self-management
  programs.home-manager.enable = true;

  services.clip-sync.enable = true;

  services.open-design = {
    enable = true;
    autoStart = true;
    port = 7457;
    webFrontend = {
      enable = true;
      host = "0.0.0.0";
      port = 38471;
      allowedOrigins = [
        "http://vd.netbird.cloud:38471"
        "http://localhost:38471"
        "http://127.0.0.1:38471"
      ];
    };
    mcp = {
      enable = true;
      port = 38472;
    };
  };

  services.shadoword-desktop = {
    enable = true;
    environment = {
      PATH = "/run/current-system/sw/bin:/etc/profiles/per-user/${username}/bin:/run/wrappers/bin";
      # Keep the NVIDIA/Hyprland WebKit workaround local to this host.
      GDK_BACKEND = "x11";
      WEBKIT_DISABLE_DMABUF_RENDERER = "1";
    };
  };

}
