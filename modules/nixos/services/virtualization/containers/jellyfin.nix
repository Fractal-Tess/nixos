{ config, lib, pkgs, ... }:

with lib;

let cfg = config.modules.services.virtualization.containers.jellyfin;
in {
  options.modules.services.virtualization.containers.jellyfin = {
    enable = mkEnableOption "Enable Jellyfin Media Server";

    # Media directories configuration
    mediaDirectories = mkOption {
      type = types.listOf types.str;
      description = "List of media directories to mount in the container";
      example = [ "/media/movies" "/media/tv" "/media/music" ];
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
      uid = 1000; # Standard media server UID
    };

    users.groups.${cfg.group} = {
      gid = 1000; # Standard media server GID
    };

    # Create persistent directories for Jellyfin data
    systemd.tmpfiles.rules = [
      # Config directory
      "d /var/lib/jellyfin/config 0755 ${cfg.user} ${cfg.group} -"
      # Cache directory
      "d /var/lib/jellyfin/cache 0755 ${cfg.user} ${cfg.group} -"
      # Log directory
      "d /var/lib/jellyfin/log 0755 ${cfg.user} ${cfg.group} -"
    ];

    # Define the Jellyfin container service
    virtualisation.oci-containers.containers.jellyfin = {
      autoStart = true;
      image = "jellyfin/jellyfin:2025072105";

      # Configure ports
      ports = [
        "${toString cfg.httpPort}:8096" # HTTP Web UI
        "${toString cfg.httpsPort}:8920" # HTTPS Web UI (if enabled)
        "7359:7359/udp" # Allows clients to discover Jellyfin on the local network
        "1900:1900/udp" # Service discovery used by DNLA and clients
      ];

      # Configure volumes
      volumes = [
        # Jellyfin data directories
        "/var/lib/jellyfin/config:/config"
        "/var/lib/jellyfin/cache:/cache"
        "/var/lib/jellyfin/log:/log"
      ] ++
        # Add media directories
        (map (dir: "${dir}:${dir}") cfg.mediaDirectories);

      # Environment variables for user/group permissions and GPU support
      environment = {
        PUID = "1000";
        PGID = "1000";
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
    networking.firewall = {
      allowedTCPPorts = [ cfg.httpPort cfg.httpsPort ];
      allowedUDPPorts = [ 7359 1900 ];
    };

    # Ensure required system packages are available
    environment.systemPackages = with pkgs;
      [
        # FFmpeg for media transcoding (Jellyfin will use the container's version, but good to have)
        ffmpeg
      ];
  };
}
