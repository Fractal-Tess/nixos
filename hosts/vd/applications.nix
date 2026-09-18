{
  config,
  lib,
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
  # PERSONAL PROJECT SYSTEM SERVICES
  #============================================================================
  # Read by systemd (as root) into the daemon's credential store, not by the
  # daemon itself, so it deliberately stays out of reach of the login user.

  sops.secrets.shadoword_admin_token = {
    sopsFile = ../../secrets/shadoword.json;
    format = "json";
    owner = "root";
    group = "root";
    mode = "0400";
  };

  sops.secrets.shadoword_user_token = {
    sopsFile = ../../secrets/shadoword.json;
    format = "json";
    owner = username;
    group = "users";
    mode = "0400";
  };

  sops.secrets.clip_sync_mesh_key = {
    sopsFile = ../../secrets/clip-sync.json;
    format = "json";
    owner = username;
    group = "users";
    mode = "0400";
  };

  programs.asterveil.enable = true;
  programs.responsively.enable = true;

  services.chorus = {
    enable = true;
    engines = [ "kokoro" ];
    devices = [
      "cpu"
      "cuda:0"
    ];
    host = "0.0.0.0";
    port = 8000;
    openFirewall = false;
    downloadMissing = true;
    preload = [ "kokoro/82m-v1.0" ];
  };

  services.shadoword-api = {
    enable = true;
    variant = "cuda";
    listenAddress = "100.91.0.2";
    requestRecordingDir = "/var/lib/shadoword/requests";
    initTokenFile = config.sops.secrets.shadoword_admin_token.path;
  };

  # The listen address is a NetBird address, so the interface has to exist
  # before the daemon can bind it.
  systemd.services.shadoword-api.after = [ "netbird.service" ];

  # Reachable over the mesh only; `openFirewall` would expose it everywhere.
  networking.firewall.interfaces.wt0.allowedTCPPorts = [
    47813
    8000
  ];

  systemd.tmpfiles.rules = [
    "d /home/${username}/.config/shadoword 0700 ${username} users -"
  ];

  #============================================================================
  # PERSONAL PROJECT USER SERVICES
  #============================================================================

  home-manager.users."${username}" = {
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
  };
}
