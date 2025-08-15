{ config, lib, pkgs, mkBackupService, mkBackupTimer, mkBackupDirectories
, mkRestoreScript, ... }:

with lib;

let
  cfg = config.modules.services.virtualization.containers.qbittorrent;
  # Determine user/group for container and directories
  user = if cfg.user != null then cfg.user.name else "1000";
  group = if cfg.user != null then cfg.user.name else "1000";
  uid = if cfg.user != null then cfg.user.uid else 1000;
  gid = if cfg.user != null then cfg.user.gid else 1000;
in {
  options.modules.services.virtualization.containers.qbittorrent = {
    enable = mkEnableOption "Enable qBittorrent BitTorrent Client";

    # Image configuration
    image = mkOption {
      type = types.str;
      default = "linuxserver/qbittorrent";
      description = "Docker image name for qBittorrent";
      example = "linuxserver/qbittorrent";
    };

    imageTag = mkOption {
      type = types.str;
      default = "latest";
      description = "Docker image tag for qBittorrent";
      example = "latest";
    };

    # Port configuration
    webPort = mkOption {
      type = types.port;
      default = 8080;
      description = "HTTP port for qBittorrent web interface";
    };

    # User/Group configuration
    user = mkOption {
      type = types.nullOr (types.submodule {
        options = {
          name = mkOption {
            type = types.str;
            description = "Name of the user to create and run qBittorrent as";
            example = "qbittorrent";
          };
          uid = mkOption {
            type = types.int;
            description = "User ID for qBittorrent service";
            example = 1005;
          };
          gid = mkOption {
            type = types.int;
            description = "Group ID for qBittorrent service";
            example = 1005;
          };
        };
      });
      default = null;
      description =
        "Custom user configuration. If null, uses default user 1000 without creating new users";
      example = {
        name = "qbittorrent";
        uid = 1005;
        gid = 1005;
      };
    };

    # Firewall configuration
    openFirewallPorts = mkOption {
      type = types.bool;
      default = false;
      description = "Open firewall ports for qBittorrent";
    };

    # Bind mounts configuration
    bindMounts = mkOption {
      type = types.listOf (types.submodule {
        options = {
          hostPath = mkOption {
            type = types.str;
            description = "Path on the host system";
            example = "/var/lib/qbittorrent/config";
          };
          containerPath = mkOption {
            type = types.str;
            description = "Path inside the container";
            example = "/config";
          };
          readOnly = mkOption {
            type = types.bool;
            default = false;
            description = "Mount as read-only";
          };
          backup = mkOption {
            type = types.bool;
            default = true;
            description = "Include this bind mount in backup process";
          };
        };
      });
      default = [
        {
          hostPath = "/var/lib/qbittorrent/config";
          containerPath = "/config";
          readOnly = false;
          backup = true;
        }
        {
          hostPath = "/var/lib/qbittorrent/downloads";
          containerPath = "/downloads";
          readOnly = false;
          backup = false;
        }
        {
          hostPath = "/var/lib/qbittorrent/torrents";
          containerPath = "/torrents";
          readOnly = false;
          backup = false;
        }
      ];
      description = "Bind mounts for qBittorrent container";
      example = [
        {
          hostPath = "/var/lib/qbittorrent/config";
          containerPath = "/config";
          readOnly = false;
          backup = true;
        }
        {
          hostPath = "/media/torrents";
          containerPath = "/media/torrents";
          readOnly = true;
          backup = false;
        }
      ];
    };

    # Backup configuration
    backup = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable automatic daily backup of qBittorrent data";
      };

      schedule = mkOption {
        type = types.str;
        default = "0 23 * * *"; # Daily at 11PM
        description = "Cron schedule for backup";
        example = "0 23 * * *"; # Daily at 11PM
      };

      paths = mkOption {
        type = types.listOf types.str;
        default = [ "/var/backups/qbittorrent" ];
        description = "List of backup destination directories";
        example = [
          "/var/backups/qbittorrent"
          "/mnt/backup/qbittorrent"
          "/mnt/cloud/qbittorrent"
        ];
      };

      format = mkOption {
        type = types.enum [ "tar.gz" "tar.xz" "tar.bz2" "zip" ];
        default = "tar.gz";
        description = "Backup archive format";
      };

      maxRetentionDays = mkOption {
        type = types.int;
        default = 0;
        description = "Maximum age of backup files in days (0 = no age limit)";
        example = 30;
      };

      retentionSnapshots = mkOption {
        type = types.int;
        default = 7;
        description = "Number of backup snapshots to keep (0 = keep all)";
        example = 10;
      };
    };
  };

  config = mkIf cfg.enable {
    # Create system user and group for qBittorrent if custom user is specified
    users.users = mkIf (cfg.user != null) {
      ${cfg.user.name} = {
        isSystemUser = true;
        group = cfg.user.name;
        description = "qBittorrent service user";
        uid = cfg.user.uid;
      };
    };

    users.groups =
      mkIf (cfg.user != null) { ${cfg.user.name} = { gid = cfg.user.gid; }; };

    # Create persistent directories for qBittorrent data
    systemd.tmpfiles.rules =
      # Create directories for all bind mounts
      (map (mount: "d ${mount.hostPath} 0755 ${user} ${group} -")
        cfg.bindMounts) ++ mkBackupDirectories {
          backupConfig = cfg.backup;
          user = user;
          group = group;
        };

    # Define the qBittorrent container service
    virtualisation.oci-containers.containers.qbittorrent = {
      autoStart = true;
      image = "${cfg.image}:${cfg.imageTag}";

      # Configure ports
      ports = [
        "${toString cfg.webPort}:8080" # Web UI
      ];

      # Configure volumes
      volumes =
        # Convert bindMounts to volume strings
        (map (mount:
          if mount.readOnly then
            "${mount.hostPath}:${mount.containerPath}:ro"
          else
            "${mount.hostPath}:${mount.containerPath}") cfg.bindMounts);

      # Environment variables for user/group permissions and timezone
      environment = {
        PUID = toString uid;
        PGID = toString gid;
        TZ = config.time.timeZone or "UTC";
        WEBUI_PORT = "8080";
      };

      # Extra options for security and networking
      extraOptions = [
        # Network mode for better discovery
        "--network=host"
        # Security option
        "--security-opt=no-new-privileges:false"
      ];
    };

    # Open firewall ports for qBittorrent
    networking.firewall =
      mkIf cfg.openFirewallPorts { allowedTCPPorts = [ cfg.webPort ]; };

    # Backup service configuration using utility
    systemd.services.qbittorrent-backup = mkIf cfg.backup.enable
      (mkBackupService {
        name = "qbittorrent";
        serviceName = "docker-qbittorrent.service";
        dataPaths =
          # Get host paths from bind mounts that are marked for backup
          (map (mount: mount.hostPath)
            (filter (mount: mount.backup) cfg.bindMounts));
        user = user;
        group = group;
        backupConfig = cfg.backup;
      });

    # Setup timer for backup service using utility
    systemd.timers.qbittorrent-backup = mkIf cfg.backup.enable (mkBackupTimer {
      name = "qbittorrent";
      backupConfig = cfg.backup;
    });

    # Create restore script
    systemd.services.qbittorrent-restore = mkIf cfg.backup.enable
      (mkRestoreScript {
        name = "qbittorrent";
        dataPaths =
          # Get host paths from bind mounts that are marked for backup
          (map (mount: mount.hostPath)
            (filter (mount: mount.backup) cfg.bindMounts));
        user = user;
        group = group;
        backupConfig = cfg.backup;
      });

  };
}
