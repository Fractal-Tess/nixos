{
  config,
  inputs,
  lib,
  pkgs,
  username,
  ...
}:

{
  imports = [
    inputs.gitadel.nixosModules.default
    inputs.gitadel.nixosModules.gitadel-cli
    inputs.immich-flake.nixosModules.default
    inputs.oh-my-pi-flake.nixosModules.default
    inputs.claude-code-flake.nixosModules.default
    inputs.codex-flake.nixosModules.default
    inputs.opencode-flake.nixosModules.default
  ];

  config = lib.mkMerge [
    # T3 Code
    {
      modules.services.t3code-server.enable = true;
    }

    # OMP
    {
      programs.omp.enable = lib.mkDefault true;
    }

    # Claude Code
    {
      programs.claude-code.enable = true;
    }

    # Codex
    {
      programs.codex.enable = true;
    }

    # opencode
    {
      programs.opencode.enable = true;
    }

    # ClipSync
    {
      home-manager.users.${username}.services.clip-sync = {
        enable = true;
        configFile = ./clip-sync.toml;
        wantedBy = [ "default.target" ];
      };
      sops.secrets.clip_sync_mesh_key = {
        sopsFile = ../../secrets/clip-sync.json;
        format = "json";
        owner = username;
        group = "users";
        mode = "0400";
      };
    }

    # Immich
    {
      services.immich = {
        enable = true;
        host = "0.0.0.0";
        openFirewall = true;
        # Existing library, previously bind-mounted into the Dokploy container
        mediaLocation = "/mnt/blockade/services/neo-immich-egyjka/uploads";
        # VA-API transcoding on the AMD iGPU
        accelerationDevices = [ "/dev/dri/renderD128" ];
      };
      users.users.immich.extraGroups = [
        "video"
        "render"
      ];
      # Database was restored into PostgreSQL 17; keep it pinned
      services.postgresql.package = pkgs.postgresql_17;
    }

    # Media stack, formerly the Dokploy compose stack next to Jellyfin
    {
      # Sonarr, Radarr and qBittorrent run as the media owner so imports and
      # hardlinks keep working across the libraries and the downloads folder.
      services.sonarr = {
        enable = true;
        openFirewall = true;
        user = username;
        group = "users";
        dataDir = "/mnt/blockade/services/sonarr/config";
      };
      services.radarr = {
        enable = true;
        openFirewall = true;
        user = username;
        group = "users";
        dataDir = "/mnt/blockade/services/radarr/config";
      };
      services.prowlarr = {
        enable = true;
        openFirewall = true;
        dataDir = "/mnt/blockade/services/prowlarr/config";
      };
      services.qbittorrent = {
        enable = true;
        openFirewall = true;
        user = username;
        group = "users";
        profileDir = "/mnt/blockade/services/qbittorrent/profile";
        webuiPort = 18080;
        torrentingPort = 6881;
      };
      services.seerr = {
        enable = true;
        openFirewall = true;
      };

      # The databases still refer to media by the container paths and to each
      # other by the compose service names.
      systemd.services.sonarr.serviceConfig.BindPaths = [
        "/mnt/blockade/services/jellyfin/tvshows:/tv"
        "/mnt/blockade/services/qbittorrent/downloads:/downloads"
      ];
      systemd.services.radarr.serviceConfig.BindPaths = [
        "/mnt/blockade/services/jellyfin/movies:/movies"
        "/mnt/blockade/services/qbittorrent/downloads:/downloads"
      ];
      systemd.services.qbittorrent.serviceConfig.BindPaths = [
        "/mnt/blockade/services/qbittorrent/downloads:/downloads"
      ];
      networking.hosts."127.0.0.1" = [
        "jellyfin"
        "sonarr"
        "radarr"
        "prowlarr"
        "qbittorrent"
      ];
    }

    # Gitadel
    {
      programs.gitadel-cli = {
        enable = lib.mkDefault true;
        serverUrl = lib.mkDefault "http://neo.netbird.cloud:3030";
        tokenFile = config.sops.secrets.gitadel_api_token.path;
      };
      sops.secrets.gitadel_api_token = lib.mkIf config.modules.services.sops.enable {
        owner = username;
        group = "users";
        mode = "0600";
        sopsFile = ../../secrets/gitadel.json;
        format = "json";
      };
      services.gitadel = {
        enable = true;
        publicUrl = "http://neo.netbird.cloud:3030";
        http = {
          address = "0.0.0.0";
          port = 3030;
        };
        ssh = {
          address = "0.0.0.0";
          port = 2222;
        };
      };
      systemd.tmpfiles.rules = [
        "d /mnt/blockade/services/gitadel 0750 gitadel gitadel -"
        "d /mnt/blockade/services/gitadel-backups 0750 gitadel gitadel -"
      ];
      # ProtectSystem=strict requires explicit write access outside /var/lib/gitadel.
      systemd.services.gitadel.serviceConfig.ReadWritePaths = [
        "/mnt/blockade/services/gitadel"
        "/mnt/blockade/services/gitadel-backups"
      ];
      networking.firewall.interfaces.wt0.allowedTCPPorts = [
        3030
        2222
      ];
    }
  ];
}
