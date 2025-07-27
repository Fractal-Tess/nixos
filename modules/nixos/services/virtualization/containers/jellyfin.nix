{ config, lib, pkgs, mkBackupService, mkBackupTimer, mkBackupDirectories
, mkRestoreScript, ... }:

with lib;

let cfg = config.modules.services.virtualization.containers.jellyfin;
in {
  options.modules.services.virtualization.containers.jellyfin = {
    enable = mkEnableOption "Enable Jellyfin Media Server";

    # Image configuration
    image = mkOption {
      type = types.str;
      default = "jellyfin/jellyfin";
      description = "Docker image name for Jellyfin";
      example = "jellyfin/jellyfin";
    };

    imageTag = mkOption {
      type = types.str;
      default = "latest";
      description = "Docker image tag for Jellyfin";
      example = "latest";
    };

    # Port configuration
    httpPort = mkOption {
      type = types.port;
      default = 8096;
      description = "HTTP port for Jellyfin web interface";
    };

    httpsPort = mkOption {
      type = types.port;
      default = 8920;
      description = "HTTPS port for Jellyfin web interface";
    };

    # Hardware acceleration
    enableHardwareAcceleration = mkOption {
      type = types.bool;
      default = false;
      description =
        "Enable hardware acceleration (requires appropriate GPU drivers)";
    };

    # User/Group configuration
    user = mkOption {
      type = types.str;
      default = "jellyfin";
      description = "User to run Jellyfin as";
    };

    group = mkOption {
      type = types.str;
      default = "jellyfin";
      description = "Group to run Jellyfin as";
    };

    uid = mkOption {
      type = types.int;
      description = "User ID for Jellyfin service";
      example = 1001;
    };

    gid = mkOption {
      type = types.int;
      description = "Group ID for Jellyfin service";
      example = 1001;
    };

    # Firewall configuration
    openFirewallPorts = mkOption {
      type = types.bool;
      default = false;
      description = "Open firewall ports for Jellyfin";
    };

    # Bind mounts configuration
    bindMounts = mkOption {
      type = types.listOf (types.submodule {
        options = {
          hostPath = mkOption {
            type = types.str;
            description = "Path on the host system";
            example = "/var/lib/jellyfin/config";
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
      description = "Bind mounts for Jellyfin container";
      example = [
        {
          hostPath = "/var/lib/jellyfin/config";
          containerPath = "/config";
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
        description = "Enable automatic daily backup of Jellyfin data";
      };

      schedule = mkOption {
        type = types.str;
        description = "Cron schedule for backup";
        example = "0 2 * * *"; # Daily at 2 AM
      };

      paths = mkOption {
        type = types.listOf types.str;
        default = [ "/var/backups/jellyfin" ];
        description = "List of backup destination directories";
        example = [
          "/var/backups/jellyfin"
          "/mnt/backup/jellyfin"
          "/mnt/cloud/jellyfin"
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

      includeLogs = mkOption {
        type = types.bool;
        default = true;
        description = "Include log files in backup";
      };

      includeCache = mkOption {
        type = types.bool;
        default = false;
        description = "Include cache files in backup (can be large)";
      };
    };
  };

  config = mkIf cfg.enable {
    # Detect if NVIDIA support is available
    assertions = [{
      assertion = !cfg.enableHardwareAcceleration
        || (config.modules.drivers.nvidia.enable or false)
        || (config.modules.drivers.amd.enable or false);
      message =
        "Hardware acceleration requires either NVIDIA or AMD drivers to be enabled";
    }];

    # Create system user and group for Jellyfin
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      description = "Jellyfin service user";
      uid = cfg.uid;
    };

    users.groups.${cfg.group} = { gid = cfg.gid; };

    # Create persistent directories for Jellyfin data
    systemd.tmpfiles.rules =
      # Create directories for all bind mounts
      (map (mount: "d ${mount.hostPath} 0755 ${cfg.user} ${cfg.group} -")
        cfg.bindMounts) ++ mkBackupDirectories {
          backupConfig = cfg.backup;
          user = cfg.user;
          group = cfg.group;
        };

    # Define the Jellyfin container service
    virtualisation.oci-containers.containers.jellyfin = {
      autoStart = true;
      image = "${cfg.image}:${cfg.imageTag}";

      # Configure ports
      ports = [
        "${toString cfg.httpPort}:8096" # HTTP Web UI
        "${toString cfg.httpsPort}:8920" # HTTPS Web UI (if enabled)
        "7359:7359/udp" # Allows clients to discover Jellyfin on the local network
        "1900:1900/udp" # Service discovery used by DNLA and clients
      ];

      # Configure volumes
      volumes =
        # Convert bindMounts to volume strings
        (map (mount:
          if mount.readOnly then
            "${mount.hostPath}:${mount.containerPath}:ro"
          else
            "${mount.hostPath}:${mount.containerPath}") cfg.bindMounts);

      # Environment variables for user/group permissions and GPU support
      environment = {
        PUID = toString cfg.uid;
        PGID = toString cfg.gid;
        TZ = config.time.timeZone or "UTC";
      } // (optionalAttrs (cfg.enableHardwareAcceleration
        && (config.modules.drivers.nvidia.enable or false)) {
          # NVIDIA-specific environment variables
          NVIDIA_VISIBLE_DEVICES = "all";
          NVIDIA_DRIVER_CAPABILITIES = "compute,video,utility";
        });

      # Extra options for hardware acceleration and other features
      extraOptions = [
        # Network mode for better discovery
        "--network=host"
        # Security option for GPU access
        "--security-opt=no-new-privileges:false"
      ] ++
        # Add hardware acceleration if enabled
        (optionals cfg.enableHardwareAcceleration
          (if (config.modules.drivers.nvidia.enable or false) then
            [
              # NVIDIA GPU acceleration using CDI (Container Device Interface)
              "--device=nvidia.com/gpu=all"
            ]
          else [
            # Intel/AMD GPU acceleration  
            "--device=/dev/dri:/dev/dri"
            "--device=/dev/video0:/dev/video0"
          ]));
    };

    # Open firewall ports for Jellyfin
    networking.firewall = mkIf cfg.openFirewallPorts {
      allowedTCPPorts = [ cfg.httpPort cfg.httpsPort ];
      allowedUDPPorts = [ 7359 1900 ];
    };

    # Backup service configuration using utility
    systemd.services.jellyfin-backup = mkIf cfg.backup.enable (mkBackupService {
      name = "jellyfin";
      serviceName = "docker-jellyfin.service";
      dataPaths =
        # Get host paths from bind mounts that are marked for backup
        (map (mount: mount.hostPath)
          (filter (mount: mount.backup) cfg.bindMounts));
      user = cfg.user;
      group = cfg.group;
      backupConfig = cfg.backup;
    });

    # Setup timer for backup service using utility
    systemd.timers.jellyfin-backup = mkIf cfg.backup.enable (mkBackupTimer {
      name = "jellyfin";
      backupConfig = cfg.backup;
    });

    # Create restore script
    systemd.services.jellyfin-restore = mkIf cfg.backup.enable
      (mkRestoreScript {
        name = "jellyfin";
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
