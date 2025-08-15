{ config, lib, pkgs, mkBackupService, mkBackupTimer, mkBackupDirectories
, mkRestoreScript, ... }:

with lib;

let
  cfg = config.modules.services.virtualization.containers.jellyseerr;
  # Determine user/group for container and directories
  user = if cfg.user != null then cfg.user.name else "1000";
  group = if cfg.user != null then cfg.user.name else "1000";
  uid = if cfg.user != null then cfg.user.uid else 1000;
  gid = if cfg.user != null then cfg.user.gid else 1000;
in {
  options.modules.services.virtualization.containers.jellyseerr = {
    enable = mkEnableOption "Enable Jellyseerr Request Management";

    # Image configuration
    image = mkOption {
      type = types.str;
      default = "fallenbagel/jellyseerr";
      description = "Docker image name for Jellyseerr";
      example = "fallenbagel/jellyseerr";
    };

    imageTag = mkOption {
      type = types.str;
      default = "latest";
      description = "Docker image tag for Jellyseerr";
      example = "latest";
    };

    # Port configuration
    webPort = mkOption {
      type = types.port;
      default = 5055;
      description = "HTTP port for Jellyseerr web interface";
    };

    # User/Group configuration
    user = mkOption {
      type = types.nullOr (types.submodule {
        options = {
          name = mkOption {
            type = types.str;
            description = "Name of the user to create and run Jellyseerr as";
            example = "jellyseerr";
          };
          uid = mkOption {
            type = types.int;
            description = "User ID for Jellyseerr service";
            example = 1007;
          };
          gid = mkOption {
            type = types.int;
            description = "Group ID for Jellyseerr service";
            example = 1007;
          };
        };
      });
      default = null;
      description =
        "Custom user configuration. If null, uses default user 1000 without creating new users";
      example = {
        name = "jellyseerr";
        uid = 1007;
        gid = 1007;
      };
    };

    # Firewall configuration
    openFirewallPorts = mkOption {
      type = types.bool;
      default = false;
      description = "Open firewall ports for Jellyseerr";
    };

    # Bind mounts configuration
    bindMounts = mkOption {
      type = types.listOf (types.submodule {
        options = {
          hostPath = mkOption {
            type = types.str;
            description = "Path on the host system";
            example = "/var/lib/jellyseerr/config";
          };
          containerPath = mkOption {
            type = types.str;
            description = "Path inside the container";
            example = "/app/config";
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
          hostPath = "/var/lib/jellyseerr/config";
          containerPath = "/app/config";
          readOnly = false;
          backup = true;
        }
        {
          hostPath = "/var/lib/jellyseerr/cache";
          containerPath = "/app/cache";
          readOnly = false;
          backup = false;
        }
      ];
      description = "Bind mounts for Jellyseerr container";
      example = [
        {
          hostPath = "/var/lib/jellyseerr/config";
          containerPath = "/app/config";
          readOnly = false;
          backup = true;
        }
        {
          hostPath = "/media/movies";
          containerPath = "/media/movies";
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
        description = "Enable automatic daily backup of Jellyseerr data";
      };

      schedule = mkOption {
        type = types.str;
        default = "0 0 * * *"; # Daily at midnight
        description = "Cron schedule for backup";
        example = "0 0 * * *"; # Daily at midnight
      };

      paths = mkOption {
        type = types.listOf types.str;
        default = [ "/var/backups/jellyseerr" ];
        description = "List of backup destination directories";
        example = [
          "/var/backups/jellyseerr"
          "/mnt/backup/jellyseerr"
          "/mnt/cloud/jellyseerr"
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
    # Create system user and group for Jellyseerr if custom user is specified
    users.users = mkIf (cfg.user != null) {
      ${cfg.user.name} = {
        isSystemUser = true;
        group = cfg.user.name;
        description = "Jellyseerr service user";
        uid = cfg.user.uid;
      };
    };

    users.groups =
      mkIf (cfg.user != null) { ${cfg.user.name} = { gid = cfg.user.gid; }; };

    # Create persistent directories for Jellyseerr data
    systemd.tmpfiles.rules =
      # Create directories for all bind mounts
      (map (mount: "d ${mount.hostPath} 0755 ${user} ${group} -")
        cfg.bindMounts) ++ mkBackupDirectories {
          backupConfig = cfg.backup;
          user = user;
          group = group;
        };

    # Define the Jellyseerr container service
    virtualisation.oci-containers.containers.jellyseerr = {
      autoStart = true;
      image = "${cfg.image}:${cfg.imageTag}";

      # Configure ports
      ports = [
        "${toString cfg.webPort}:5055" # Web UI
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
      };

      # Extra options for security and networking
      extraOptions = [
        # Network mode for better discovery
        "--network=host"
        # Security option
        "--security-opt=no-new-privileges:false"
      ];
    };

    # Open firewall ports for Jellyseerr
    networking.firewall =
      mkIf cfg.openFirewallPorts { allowedTCPPorts = [ cfg.webPort ]; };

    # Backup service configuration using utility
    systemd.services.jellyseerr-backup = mkIf cfg.backup.enable
      (mkBackupService {
        name = "jellyseerr";
        serviceName = "docker-jellyseerr.service";
        dataPaths =
          # Get host paths from bind mounts that are marked for backup
          (map (mount: mount.hostPath)
            (filter (mount: mount.backup) cfg.bindMounts));
        user = user;
        group = group;
        backupConfig = cfg.backup;
      });

    # Setup timer for backup service using utility
    systemd.timers.jellyseerr-backup = mkIf cfg.backup.enable (mkBackupTimer {
      name = "jellyseerr";
      backupConfig = cfg.backup;
    });

    # Create restore script
    systemd.services.jellyseerr-restore = mkIf cfg.backup.enable
      (mkRestoreScript {
        name = "jellyseerr";
        dataPaths =
          # Get host paths from bind mounts that are marked for backup
          (map (mount: mount.hostPath)
            (filter (mount: mount.backup) cfg.bindMounts));
        user = user;
        group = user;
        backupConfig = cfg.backup;
      });

  };
}
