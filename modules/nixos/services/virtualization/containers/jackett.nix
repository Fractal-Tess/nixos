{ config, lib, pkgs, mkBackupService, mkBackupTimer, mkBackupDirectories
, mkRestoreScript, ... }:

with lib;

let cfg = config.modules.services.virtualization.containers.jackett;
in {
  options.modules.services.virtualization.containers.jackett = {
    enable = mkEnableOption "Enable Jackett Torrent Proxy Server";

    # Image configuration
    image = mkOption {
      type = types.str;
      default = "linuxserver/jackett";
      description = "Docker image name for Jackett";
      example = "linuxserver/jackett";
    };

    imageTag = mkOption {
      type = types.str;
      default = "latest";
      description = "Docker image tag for Jackett";
      example = "latest";
    };

    # Port configuration
    httpPort = mkOption {
      type = types.port;
      default = 9117;
      description = "HTTP port for Jackett web interface";
    };

    # User/Group configuration
    user = mkOption {
      type = types.str;
      default = "jackett";
      description = "User to run Jackett as";
    };

    group = mkOption {
      type = types.str;
      default = "jackett";
      description = "Group to run Jackett as";
    };

    uid = mkOption {
      type = types.int;
      description = "User ID for Jackett service";
      example = 1004;
    };

    gid = mkOption {
      type = types.int;
      description = "Group ID for Jackett service";
      example = 1004;
    };

    # Firewall configuration
    openFirewallPorts = mkOption {
      type = types.bool;
      default = false;
      description = "Open firewall ports for Jackett";
    };

    # Bind mounts configuration
    bindMounts = mkOption {
      type = types.listOf (types.submodule {
        options = {
          hostPath = mkOption {
            type = types.str;
            description = "Path on the host system";
            example = "/var/lib/jackett/config";
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
          hostPath = "/var/lib/jackett/config";
          containerPath = "/config";
          readOnly = false;
          backup = true;
        }
        {
          hostPath = "/var/lib/jackett/downloads";
          containerPath = "/downloads";
          readOnly = false;
          backup = false;
        }
      ];
      description = "Bind mounts for Jackett container";
      example = [
        {
          hostPath = "/var/lib/jackett/config";
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
        description = "Enable automatic daily backup of Jackett data";
      };

      schedule = mkOption {
        type = types.str;
        default = "0 22 * * *"; # Daily at 10PM
        description = "Cron schedule for backup";
        example = "0 22 * * *"; # Daily at 10PM
      };

      paths = mkOption {
        type = types.listOf types.str;
        default = [ "/var/backups/jackett" ];
        description = "List of backup destination directories";
        example =
          [ "/var/backups/jackett" "/mnt/backup/jackett" "/mnt/cloud/jackett" ];
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
    # Create system user and group for Jackett
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      description = "Jackett service user";
      uid = cfg.uid;
    };

    users.groups.${cfg.group} = { gid = cfg.gid; };

    # Create persistent directories for Jackett data
    systemd.tmpfiles.rules =
      # Create directories for all bind mounts
      (map (mount: "d ${mount.hostPath} 0755 ${cfg.user} ${cfg.group} -")
        cfg.bindMounts) ++ mkBackupDirectories {
          backupConfig = cfg.backup;
          user = cfg.user;
          group = cfg.group;
        };

    # Define the Jackett container service
    virtualisation.oci-containers.containers.jackett = {
      autoStart = true;
      image = "${cfg.image}:${cfg.imageTag}";

      # Configure ports
      ports = [
        "${toString cfg.httpPort}:9117" # HTTP Web UI
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
        PUID = toString cfg.uid;
        PGID = toString cfg.gid;
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

    # Open firewall ports for Jackett
    networking.firewall =
      mkIf cfg.openFirewallPorts { allowedTCPPorts = [ cfg.httpPort ]; };

    # Backup service configuration using utility
    systemd.services.jackett-backup = mkIf cfg.backup.enable (mkBackupService {
      name = "jackett";
      serviceName = "docker-jackett.service";
      dataPaths =
        # Get host paths from bind mounts that are marked for backup
        (map (mount: mount.hostPath)
          (filter (mount: mount.backup) cfg.bindMounts));
      user = cfg.user;
      group = cfg.group;
      backupConfig = cfg.backup;
    });

    # Setup timer for backup service using utility
    systemd.timers.jackett-backup = mkIf cfg.backup.enable (mkBackupTimer {
      name = "jackett";
      backupConfig = cfg.backup;
    });

    # Create restore script
    systemd.services.jackett-restore = mkIf cfg.backup.enable (mkRestoreScript {
      name = "jackett";
      dataPaths =
        # Get host paths from bind mounts that are marked for backup
        (map (mount: mount.hostPath)
          (filter (mount: mount.backup) cfg.bindMounts));
      user = cfg.user;
      group = cfg.group;
      backupConfig = cfg.backup;
    });

  };
}
