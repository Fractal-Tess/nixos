{
  pkgs,
  username,
  ...
}:

# Home-server role, moved here from neo on 2026-11-09 together with the
# "blockade" USB disk. Media, photo and library data live on blockade; small
# service state lives under /var/lib.
let
  blockade = "/mnt/blockade";
  services = "${blockade}/services";
in
{
  #============================================================================
  # STORAGE
  #============================================================================

  # External USB disk; nofail so vd still boots when it is unplugged.
  fileSystems.${blockade} = {
    device = "/dev/disk/by-uuid/f0958b59-82df-4344-81c4-53b3c4bcc2bd";
    fsType = "ext4";
    options = [
      "nofail"
      "x-systemd.device-timeout=15s"
    ];
  };

  # Every service that keeps data on blockade waits for it.
  systemd.services =
    let
      needsBlockade = {
        unitConfig.RequiresMountsFor = [ blockade ];
      };
    in
    {
      immich-server = needsBlockade;
      immich-machine-learning = needsBlockade;
      jellyfin = needsBlockade // {
        # The libraries were created inside a container, so the database
        # still refers to the media by its container paths.
        serviceConfig.BindPaths = [
          "${services}/jellyfin/movies:/media/movies"
          "${services}/jellyfin/tvshows:/media/tvshows"
        ];
      };
      sonarr = needsBlockade // {
        serviceConfig.BindPaths = [
          "${services}/jellyfin/tvshows:/tv"
          "${services}/qbittorrent/downloads:/downloads"
        ];
      };
      radarr = needsBlockade // {
        serviceConfig.BindPaths = [
          "${services}/jellyfin/movies:/movies"
          "${services}/qbittorrent/downloads:/downloads"
        ];
      };
      prowlarr = needsBlockade;
      qbittorrent = needsBlockade // {
        serviceConfig.BindPaths = [
          "${services}/qbittorrent/downloads:/downloads"
        ];
      };
      vaultwarden = needsBlockade;

      # Generate once on the host; never put the admin token in the Nix store.
      vaultwarden-admin-secret = {
        description = "Initialize Vaultwarden admin credential";
        before = [ "vaultwarden.service" ];
        requiredBy = [ "vaultwarden.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          StateDirectory = "vaultwarden-admin";
          StateDirectoryMode = "0700";
          UMask = "0077";
        };
        script = ''
          if [ ! -s /var/lib/vaultwarden-admin/environment ]; then
            token=$(${pkgs.openssl}/bin/openssl rand -hex 48)
            printf 'ADMIN_TOKEN=%s\n' "$token" > /var/lib/vaultwarden-admin/environment
          fi
        '';
      };
    };

  #============================================================================
  # IMMICH
  #============================================================================

  services.immich = {
    enable = true;
    host = "0.0.0.0";
    openFirewall = true;
    mediaLocation = "${services}/neo-immich-egyjka/uploads";
    # null = all devices, so transcoding can use the NVIDIA GPUs.
    accelerationDevices = null;
  };
  users.users.immich.extraGroups = [
    "video"
    "render"
  ];
  # The database was restored into PostgreSQL 17; keep it pinned.
  services.postgresql.package = pkgs.postgresql_17;

  #============================================================================
  # MEDIA STACK
  #============================================================================

  # Jellyfin, Sonarr, Radarr and qBittorrent run as the media owner so imports
  # and hardlinks keep working across the libraries and the downloads folder.
  services.jellyfin = {
    enable = true;
    openFirewall = true;
    user = username;
    group = "users";
    dataDir = "${services}/jellyfin/config";
  };
  services.sonarr = {
    enable = true;
    openFirewall = true;
    user = username;
    group = "users";
    dataDir = "${services}/sonarr/config";
  };
  services.radarr = {
    enable = true;
    openFirewall = true;
    user = username;
    group = "users";
    dataDir = "${services}/radarr/config";
  };
  services.prowlarr = {
    enable = true;
    openFirewall = true;
    dataDir = "${services}/prowlarr/config";
  };
  services.qbittorrent = {
    enable = true;
    openFirewall = true;
    user = username;
    group = "users";
    profileDir = "${services}/qbittorrent/profile";
    webuiPort = 18080;
    torrentingPort = 6881;
  };
  services.seerr = {
    enable = true;
    openFirewall = true;
  };

  # Jellyfin artwork and profile images are stored under the container's
  # data directory path.
  systemd.tmpfiles.rules = [
    "L /config - - - - ${services}/jellyfin/config"
  ];

  # The databases refer to each other by the old compose service names.
  networking.hosts."127.0.0.1" = [
    "jellyfin"
    "sonarr"
    "radarr"
    "prowlarr"
    "qbittorrent"
  ];

  #============================================================================
  # VAULTWARDEN
  #============================================================================

  # HTTPS terminates at Oracle's Traefik (see ./vaultwarden-traefik.yml),
  # which reaches this host over the NetBird mesh.
  services.vaultwarden = {
    enable = true;
    dbBackend = "sqlite";
    backupDir = "${services}/vaultwarden-backups";
    environmentFile = "/var/lib/vaultwarden-admin/environment";
    config = {
      DOMAIN = "https://vaultwarden.fractal-tess.xyz";
      ROCKET_ADDRESS = "0.0.0.0";
      ROCKET_PORT = 8222;
      SIGNUPS_ALLOWED = false;
      INVITATIONS_ALLOWED = true;
      SHOW_PASSWORD_HINT = false;
    };
  };
  # Oracle is the only peer that needs direct backend access.
  networking.firewall.extraCommands = ''
    iptables -t raw -I PREROUTING 1 ! -i lo ! -s 100.91.0.4 -p tcp --dport 8222 -j DROP
    iptables -A nixos-fw -i wt0 -s 100.91.0.4 -p tcp --dport 8222 -j nixos-fw-accept
  '';
  networking.firewall.extraStopCommands = ''
    iptables -t raw -D PREROUTING ! -i lo ! -s 100.91.0.4 -p tcp --dport 8222 -j DROP 2>/dev/null || true
    iptables -D nixos-fw -i wt0 -s 100.91.0.4 -p tcp --dport 8222 -j nixos-fw-accept 2>/dev/null || true
  '';
}
