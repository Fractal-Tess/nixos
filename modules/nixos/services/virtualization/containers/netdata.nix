{ config, lib, pkgs, mkBackupService, mkBackupTimer, mkBootBackupService
, mkBackupDirectories, ... }:

with lib;

let cfg = config.modules.services.virtualization.containers.netdata;
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
      type = types.str;
      default = "netdata";
      description = "User to run Netdata as";
    };

    group = mkOption {
      type = types.str;
      default = "netdata";
      description = "Group to run Netdata as";
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

    # Firewall configuration
    openFirewallPorts = mkOption {
      type = types.bool;
      default = false;
      description = "Open firewall ports for Netdata";
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
        default = "0 0 * * *"; # Daily at midnight
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

      bootBackup = mkOption {
        type = types.bool;
        default = true;
        description =
          "Create backup on boot if previous scheduled backup was missed";
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

    # Create system user and group for Netdata
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      description = "Netdata monitoring service user";
      uid = cfg.uid;
    };

    users.groups.${cfg.group} = { gid = cfg.gid; };

    # Create persistent directories for Netdata data and backup directories
    systemd.tmpfiles.rules = [
      # Config directory
      "d ${cfg.configDirectory} 0755 ${cfg.user} ${cfg.group} -"
      # Data directory
      "d /var/lib/netdata/lib 0755 ${cfg.user} ${cfg.group} -"
      # Cache directory
      "d /var/lib/netdata/cache 0755 ${cfg.user} ${cfg.group} -"
    ] ++ mkBackupDirectories {
      backupConfig = cfg.backup;
      user = cfg.user;
      group = cfg.group;
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
      volumes = [
        # Configuration directory
        "${cfg.configDirectory}:/etc/netdata"
        # Data directories
        "/var/lib/netdata/lib:/var/lib/netdata"
        "/var/lib/netdata/cache:/var/cache/netdata"
        # Host system information (read-only)
        "/proc:/host/proc:ro"
        "/sys:/host/sys:ro"
        "/etc/os-release:/host/etc/os-release:ro"
        # Docker socket for container monitoring
        "/var/run/docker.sock:/var/run/docker.sock"
      ];

      # Environment variables
      environment = {
        DOCKER_HOST = "unix:///var/run/docker.sock";
        PUID = toString cfg.uid;
        PGID = toString cfg.gid;
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
      dataPaths = [ cfg.configDirectory "/var/lib/netdata/lib" ];
      user = cfg.user;
      group = cfg.group;
      backupConfig = cfg.backup;
    });

    # Setup timer for backup service using utility
    systemd.timers.netdata-backup = mkIf cfg.backup.enable (mkBackupTimer {
      name = "netdata";
      backupConfig = cfg.backup;
    });

    # Boot-time backup service using utility
    systemd.services.netdata-boot-backup =
      mkIf (cfg.backup.enable && cfg.backup.bootBackup) (mkBootBackupService {
        name = "netdata";
        serviceName = "docker-netdata.service";
        dataPaths = [ cfg.configDirectory "/var/lib/netdata/lib" ];
        user = cfg.user;
        group = cfg.group;
        backupConfig = cfg.backup;
      });
  };
}
