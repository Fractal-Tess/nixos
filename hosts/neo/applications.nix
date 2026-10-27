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
    inputs.fader.nixosModules.default
    inputs.gitadel.nixosModules.default
    inputs.gitadel.nixosModules.gitadel-cli
    inputs.immich-flake.nixosModules.default
    inputs.claude-code-flake.nixosModules.default
    inputs.codex-flake.nixosModules.default
  ];

  config = lib.mkMerge [
    # Fader hub: open http://neo.netbird.cloud:7700 to control the audio
    # of neo, vd and kiwi. neo relays each change to the peer's own fader.
    {
      services.fader = {
        enable = true;
        user = username;
        port = 7700;
        # Mesh only; every device on it is ours, so no token.
        firewallInterfaces = [ "wt0" ];
        settings.peers = [
          {
            name = "vd";
            url = "http://vd.netbird.cloud:7700";
          }
          {
            name = "kiwi";
            url = "http://kiwi.netbird.cloud:7700";
          }
        ];
      };
    }

    # T3 Code
    {
      modules.services.t3code-server.enable = true;
    }

    # Claude Code
    {
      programs.claude-code.enable = true;
    }

    # Codex
    {
      programs.codex.enable = true;
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

    # Vaultwarden: HTTPS terminates at Oracle's Traefik, over the NetBird mesh.
    {
      services.vaultwarden = {
        enable = true;
        dbBackend = "sqlite";
        backupDir = "/mnt/blockade/services/vaultwarden-backups";
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
      # Generate once on the host; never put the admin token in the Nix store.
      systemd.services.vaultwarden-admin-secret = {
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
