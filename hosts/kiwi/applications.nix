{
  config,
  lib,
  pkgs,
  username,
  ...
}:

{
  #============================================================================
  # APPLICATION DEFAULTS
  #============================================================================

  programs.omp.enable = lib.mkDefault true;
  programs.scorch.enable = lib.mkDefault true;
  programs.gitadel-cli = {
    enable = lib.mkDefault true;
    serverUrl = lib.mkDefault "http://neo.netbird.cloud:3030";
    tokenFile = config.sops.secrets.gitadel_api_token.path;
  };

  services.scorchd = {
    enable = lib.mkDefault true;
    address = lib.mkDefault "0.0.0.0";
  };

  #============================================================================
  # PERSONAL APPLICATIONS
  #============================================================================

  sops.secrets.clip_sync_mesh_key = {
    sopsFile = ../../secrets/clip-sync.json;
    format = "json";
    owner = username;
    group = "users";
    mode = "0400";
  };

  programs.responsively.enable = true;

  systemd.tmpfiles.rules = [
    "d /home/${username}/.config/shadoword 0700 ${username} users -"
  ];

  environment.systemPackages = [
    pkgs.wtype
    pkgs.xdotool
  ];

  home-manager.users.${username} = {
    services.clip-sync.enable = true;

    services.shadoword-desktop = {
      enable = true;
      environment = {
        PATH = "/run/current-system/sw/bin:/etc/profiles/per-user/${username}/bin:/run/wrappers/bin";
        # Preserve this compositor's working WebKit backend.
        GDK_BACKEND = "x11";
        WEBKIT_DISABLE_DMABUF_RENDERER = "1";
      };
    };
  };
}
