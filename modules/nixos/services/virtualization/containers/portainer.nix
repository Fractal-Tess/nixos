{ config, lib, mkBackupService, mkBackupTimer, mkBackupDirectories
, mkRestoreScript, ... }:

with lib;
let cfg = config.modules.services.virtualization.containers.portainer;
in {
  options.modules.services.virtualization.containers.portainer = {
    enable = mkEnableOption "Enable Portainer";

    # Image configuration
    image = mkOption {
      type = types.str;
      default = "portainer/portainer-ce";
      description = "Docker image name for Portainer";
      example = "portainer/portainer-ce";
    };

    imageTag = mkOption {
      type = types.str;
      default = "latest";
      description = "Docker image tag for Portainer";
      example = "latest";
    };

    # User/Group configuration
    uid = mkOption {
      type = types.int;
      description = "User ID for Portainer service";
      example = 1003;
    };

    gid = mkOption {
      type = types.int;
      description = "Group ID for Portainer service";
      example = 1003;
    };

    # Firewall configuration
    openFirewallPorts = mkOption {
      type = types.bool;
      default = false;
      description = "Open firewall ports for Portainer";
    };

    # Bind mounts configuration
    bindMounts = mkOption {
      type = types.listOf (types.submodule {
        options = {
          hostPath = mkOption {
            type = types.str;
            description = "Path on the host system";
            example = "/var/lib/portainer";
          };
          containerPath = mkOption {
            type = types.str;
            description = "Path inside the container";
            example = "/data";
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
          hostPath = "/var/lib/portainer";
          containerPath = "/data";
          readOnly = false;
          backup = true;
        }
        {
          hostPath = "/run/user/1000/docker.sock";
          containerPath = "/var/run/docker.sock";
          readOnly = false;
          backup = false;
        }
      ];
      description = "Bind mounts for Portainer container";
      example = [
        {
          hostPath = "/var/lib/portainer";
          containerPath = "/data";
          readOnly = false;
          backup = true;
        }
        {
          hostPath = "/custom/portainer/templates";
          containerPath = "/templates";
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
        description = "Enable automatic backup of Portainer data";
      };

      paths = mkOption {
        type = types.listOf types.str;
        default = [ "/var/backups/portainer" ];
        description = "List of backup destination directories";
        example = [ "/var/backups/portainer" "/mnt/backup/portainer" ];
      };

      schedule = mkOption {
        type = types.str;
        description = "Cron schedule for backup";
        example = "0 2 * * *"; # Daily at 2 AM
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
    # Create system user and group for Portainer
    users.users.portainer = {
      isSystemUser = true;
      group = "portainer";
      description = "Portainer service user";
      uid = cfg.uid;
    };

    users.groups.portainer = { gid = cfg.gid; };

    # Create persistent volume directory and backup directories
    systemd.tmpfiles.rules =
      # Create directories for all bind mounts
      (map (mount: "d ${mount.hostPath} 0750 portainer portainer -")
        cfg.bindMounts) ++ mkBackupDirectories {
          backupConfig = cfg.backup;
          user = "portainer";
          group = "portainer";
        };

    # Define the Portainer service
    virtualisation.oci-containers.containers.portainer = {
      autoStart = true;
      image = "${cfg.image}:${cfg.imageTag}";
      ports = [
        "8000:8000" # Agents
        "9000:9000" # HTTP Web UI
        "9443:9443" # HTTPS Web UI
      ];
      volumes = map (mount:
        if mount.readOnly then
          "${mount.hostPath}:${mount.containerPath}:ro"
        else
          "${mount.hostPath}:${mount.containerPath}") cfg.bindMounts;
      environment = {
        PUID = toString cfg.uid;
        PGID = toString cfg.gid;
      };
      extraOptions = [ ];
    };

    # Backup service configuration using utility
    systemd.services.portainer-backup = mkIf cfg.backup.enable
      (mkBackupService {
        name = "portainer";
        serviceName = "docker-portainer.service";
        dataPaths = map (mount: mount.hostPath)
          (filter (mount: mount.backup) cfg.bindMounts);
        user = "portainer";
        group = "portainer";
        backupConfig = cfg.backup;
      });

    # Setup timer for backup service using utility
    systemd.timers.portainer-backup = mkIf cfg.backup.enable (mkBackupTimer {
      name = "portainer";
      backupConfig = cfg.backup;
    });

    # Create restore script
    systemd.services.portainer-restore = mkIf cfg.backup.enable
      (mkRestoreScript {
        name = "portainer";
        dataPaths = map (mount: mount.hostPath)
          (filter (mount: mount.backup) cfg.bindMounts);
        user = "portainer";
        group = "portainer";
        backupConfig = cfg.backup;
      });

    # Open firewall ports for Portainer
    networking.firewall =
      mkIf cfg.openFirewallPorts { allowedTCPPorts = [ 8000 9000 9443 ]; };
  };
}
