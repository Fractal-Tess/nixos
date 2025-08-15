{ config, lib, pkgs, mkBackupService, mkBackupTimer, mkBackupDirectories
, mkRestoreScript, ... }:

with lib;

let
  cfg = config.modules.services.virtualization.containers.netdata;
  # Determine user/group for container and directories
  user = if cfg.user != null then cfg.user.name else "1000";
  group = if cfg.user != null then cfg.user.name else "1000";
  uid = if cfg.user != null then cfg.user.uid else 1000;
  gid = if cfg.user != null then cfg.user.gid else 1000;
in {
  options.modules.services.virtualization.containers.netdata = {
    enable = mkEnableOption "Enable Netdata Monitoring";

    # Image configuration
    image = mkOption {
      type = types.str;
      default = "netdata/netdata";
      description = "Docker image name for Netdata";
      example = "netdata/netdata";
    };

    imageTag = mkOption {
      type = types.str;
      default = "latest";
      description = "Docker image tag for Netdata";
      example = "latest";
    };

    # Port configuration
    port = mkOption {
      type = types.port;
      default = 19999;
      description = "Port for Netdata web interface";
    };

    # User/Group configuration
    user = mkOption {
      type = types.nullOr (types.submodule {
        options = {
          name = mkOption {
            type = types.str;
            description = "Name of the user to create and run Netdata as";
            example = "netdata";
          };
          uid = mkOption {
            type = types.int;
            description = "User ID for Netdata service";
            example = 1002;
          };
          gid = mkOption {
            type = types.int;
            description = "Group ID for Netdata service";
            example = 1002;
          };
        };
      });
      default = null;
      description =
        "Custom user configuration. If null, uses default user 1000 without creating new users";
      example = {
        name = "netdata";
        uid = 1002;
        gid = 1002;
      };
    };

    # Firewall configuration
    openFirewallPorts = mkOption {
      type = types.bool;
      default = false;
      description = "Open firewall ports for Netdata";
    };

    # Bind mounts configuration
    bindMounts = mkOption {
      type = types.listOf (types.submodule {
        options = {
          hostPath = mkOption {
            type = types.str;
            description = "Path on the host system";
            example = "/var/lib/netdata/config";
          };
          containerPath = mkOption {
            type = types.str;
            description = "Path inside the container";
            example = "/etc/netdata";
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
          hostPath = "/var/lib/netdata/config";
          containerPath = "/etc/netdata";
          readOnly = false;
          backup = true;
        }
        {
          hostPath = "/var/lib/netdata/lib";
          containerPath = "/var/lib/netdata";
          readOnly = false;
          backup = true;
        }
        {
          hostPath = "/var/lib/netdata/cache";
          containerPath = "/var/cache/netdata";
          readOnly = false;
          backup = true;
        }
      ];
      description = "Bind mounts for Netdata container";
      example = [
        {
          hostPath = "/var/lib/netdata/config";
          containerPath = "/etc/netdata";
          readOnly = false;
          backup = true;
        }
        {
          hostPath = "/custom/netdata/plugins";
          containerPath = "/usr/libexec/netdata/plugins.d";
          readOnly = true;
          backup = false;
        }
      ];
    };

    # Configuration directory
    configDirectory = mkOption {
      type = types.str;
      default = "/var/lib/netdata/config";
      description = "Host directory for Netdata configuration";
    };

    # GPU monitoring configuration
    enableGpuMonitoring = mkOption {
      type = types.bool;
      default = false;
      description = "Enable GPU monitoring (requires appropriate GPU drivers)";
    };

    # Backup configuration
    backup = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable automatic backup of Netdata data";
      };

      paths = mkOption {
        type = types.listOf types.str;
        default = [ "/var/backups/netdata" ];
        description = "List of backup destination directories";
        example = [ "/var/backups/netdata" "/mnt/backup/netdata" ];
      };

      schedule = mkOption {
        type = types.str;
        default = "0 21 * * *"; # Daily at 9PM
        description = "Cron schedule for backup";
        example = "0 21 * * *"; # Daily at 9PM
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
    # Detect if GPU support is available
    assertions = [{
      assertion = !cfg.enableGpuMonitoring
        || (config.modules.drivers.nvidia.enable or false)
        || (config.modules.drivers.amd.enable or false);
      message =
        "GPU monitoring requires either NVIDIA or AMD drivers to be enabled";
    }];

    # Create system user and group for Netdata if custom user is specified
    users.users = mkIf (cfg.user != null) {
      ${cfg.user.name} = {
        isSystemUser = true;
        group = cfg.user.name;
        description = "Netdata monitoring service user";
        uid = cfg.user.uid;
      };
    };

    users.groups =
      mkIf (cfg.user != null) { ${cfg.user.name} = { gid = cfg.user.gid; }; };

    # Create persistent directories for Netdata data and backup directories
    systemd.tmpfiles.rules =
      # Create directories for all bind mounts
      (map (mount: "d ${mount.hostPath} 0755 ${user} ${group} -")
        cfg.bindMounts) ++ mkBackupDirectories {
          backupConfig = cfg.backup;
          user = user;
          group = group;
        };

    # Define the Netdata container service
    virtualisation.oci-containers.containers.netdata = {
      autoStart = true;
      image = "${cfg.image}:${cfg.imageTag}";

      # Configure ports
      ports = [
        "${toString cfg.port}:19999" # Web interface
      ];

      # Configure volumes
      volumes =
        # Convert bindMounts to volume strings
        (map (mount:
          if mount.readOnly then
            "${mount.hostPath}:${mount.containerPath}:ro"
          else
            "${mount.hostPath}:${mount.containerPath}") cfg.bindMounts) ++
        # Host system information (read-only)
        [
          "/proc:/host/proc:ro"
          "/sys:/host/sys:ro"
          "/etc/os-release:/host/etc/os-release:ro"
          # Docker socket for container monitoring
          "/var/run/docker.sock:/var/run/docker.sock"
        ];

      # Environment variables
      environment = {
        DOCKER_HOST = "unix:///var/run/docker.sock";
        PUID = toString uid;
        PGID = toString gid;
      } // (optionalAttrs (cfg.enableGpuMonitoring
        && (config.modules.drivers.nvidia.enable or false)) {
          # NVIDIA-specific environment variables
          NVIDIA_VISIBLE_DEVICES = "all";
          NVIDIA_DRIVER_CAPABILITIES = "compute,utility";
        });

      # Extra options for system access and security
      extraOptions = [
        # Required capabilities for system monitoring
        "--cap-add=SYS_PTRACE"
        # Security options
        "--security-opt=apparmor=unconfined"
        # Network mode for better host monitoring
        "--network=host"
        # Security option for GPU access
        "--security-opt=no-new-privileges:false"
      ] ++
        # Add GPU monitoring if enabled
        (optionals cfg.enableGpuMonitoring
          (if (config.modules.drivers.nvidia.enable or false) then
            [
              # NVIDIA GPU monitoring using CDI (Container Device Interface)
              "--device=nvidia.com/gpu=all"
            ]
          else
            [
              # Intel/AMD GPU monitoring
              "--device=/dev/dri:/dev/dri"
            ]));
    };

    # Note: Health checks are not supported in NixOS OCI containers module
    # Health checking can be implemented via external monitoring or systemd

    # Open firewall port for Netdata
    networking.firewall =
      mkIf cfg.openFirewallPorts { allowedTCPPorts = [ cfg.port ]; };

    # Ensure required system packages are available
    # environment.systemPackages = with pkgs; [
    #   # curl for health checks
    #   curl
    #   # Additional monitoring tools
    #   htop
    #   iotop
    #   nethogs
    # ];

    # Backup service configuration using utility
    systemd.services.netdata-backup = mkIf cfg.backup.enable (mkBackupService {
      name = "netdata";
      serviceName = "docker-netdata.service";
      dataPaths = map (mount: mount.hostPath)
        (filter (mount: mount.backup) cfg.bindMounts);
      user = user;
      group = group;
      backupConfig = cfg.backup;
    });

    # Setup timer for backup service using utility
    systemd.timers.netdata-backup = mkIf cfg.backup.enable (mkBackupTimer {
      name = "netdata";
      backupConfig = cfg.backup;
    });

    # Create restore script
    systemd.services.netdata-restore = mkIf cfg.backup.enable (mkRestoreScript {
      name = "netdata";
      dataPaths = map (mount: mount.hostPath)
        (filter (mount: mount.backup) cfg.bindMounts);
      user = user;
      group = group;
      backupConfig = cfg.backup;
    });

  };
}
