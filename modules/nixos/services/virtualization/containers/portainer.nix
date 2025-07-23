{ config, lib, mkBackupService, mkBackupTimer, mkBackupDirectories, ... }:

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
        default = "0 0 * * *"; # Daily at midnight
        description = "Cron schedule for backup";
        example = "0 2 * * *"; # Daily at 2 AM
      };

      format = mkOption {
        type = types.enum [ "tar.gz" "tar.xz" "tar.bz2" "zip" ];
        default = "tar.gz";
        description = "Backup archive format";
      };

      retention = mkOption {
        type = types.int;
        default = 7;
        description = "Number of backup files to keep (0 = keep all)";
        example = 30;
      };
    };
  };

  config = mkIf cfg.enable {
    # Create system user for Portainer
    users.users.portainer = {
      isSystemUser = true;
      group = "docker";
      description = "Portainer service user";
    };

    # Create persistent volume directory and backup directories
    systemd.tmpfiles.rules = [ "d /var/lib/portainer 0750 portainer docker -" ]
      ++ mkBackupDirectories {
        backupConfig = cfg.backup;
        user = "portainer";
        group = "docker";
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
      volumes = [
        "/run/user/1000/docker.sock:/var/run/docker.sock"
        "/var/lib/portainer:/data"
      ];
      environment = {
        PUID = "1000";
        PGID = "1000";
      };
      extraOptions = [ ];
    };

    # Backup service configuration using utility
    systemd.services.portainer-backup = mkIf cfg.backup.enable
      (mkBackupService {
        name = "portainer";
        serviceName = "docker-portainer.service";
        dataPaths = [ "/var/lib/portainer" ];
        user = "portainer";
        group = "docker";
        backupConfig = cfg.backup;
      });

    # Setup timer for backup service using utility
    systemd.timers.portainer-backup = mkIf cfg.backup.enable (mkBackupTimer {
      name = "portainer";
      backupConfig = cfg.backup;
    });
  };
}
