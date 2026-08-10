{
  pkgs,
  username,
  inputs,
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
      AGENT_BROWSER_EXECUTABLE_PATH = "${pkgs.google-chrome}/bin/google-chrome";
      HF_HOME = "/mnt/vault/ai/huggingface";
    };
  };

  # Enable Home Manager self-management
  programs.home-manager.enable = true;

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
      ExecStart = "${inputs.shadoword.packages.${pkgs.system}.shadoword-desktop}/bin/shadoword";
      Restart = "on-failure";
      RestartSec = 5;
      Environment = [
        "PATH=/run/current-system/sw/bin:/etc/profiles/per-user/${username}/bin:/run/wrappers/bin"
        # WebKitGTK's native Wayland backend mis-scales and drops SVG strokes on
        # NVIDIA/Hyprland. XWayland renders the same Tauri surface correctly.
        "GDK_BACKEND=x11"
        "WEBKIT_DISABLE_DMABUF_RENDERER=1"
      ];
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

}
