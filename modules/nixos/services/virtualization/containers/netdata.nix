{ config, lib, pkgs, ... }:

with lib;

let cfg = config.modules.services.virtualization.containers.netdata;
in {
  options.modules.services.virtualization.containers.netdata = {
    enable = mkEnableOption "Enable Netdata Monitoring";

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

    # Configuration directory
    configDirectory = mkOption {
      type = types.str;
      default = "/var/lib/netdata/config";
      description = "Host directory for Netdata configuration";
    };

  };

  config = mkIf cfg.enable {
    # Create system user and group for Netdata
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      description = "Netdata monitoring service user";
      uid = 1001; # Different from other services
    };

    users.groups.${cfg.group} = {
      gid = 1001; # Different from other services
    };

    # Create persistent directories for Netdata data
    systemd.tmpfiles.rules = [
      # Config directory
      "d ${cfg.configDirectory} 0755 ${cfg.user} ${cfg.group} -"
      # Data directory
      "d /var/lib/netdata/lib 0755 ${cfg.user} ${cfg.group} -"
      # Cache directory
      "d /var/lib/netdata/cache 0755 ${cfg.user} ${cfg.group} -"
    ];

    # Define the Netdata container service
    virtualisation.oci-containers.containers.netdata = {
      autoStart = true;
      image = "netdata/netdata:v1.47.4";

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
        PUID = "1001";
        PGID = "1001";
      };

      # Extra options for system access and security
      extraOptions = [
        # Required capabilities for system monitoring
        "--cap-add=SYS_PTRACE"
        # Security options
        "--security-opt=apparmor=unconfined"
        # Network mode for better host monitoring
        "--network=host"
      ];
    };

    # Note: Health checks are not supported in NixOS OCI containers module
    # Health checking can be implemented via external monitoring or systemd

    # Open firewall port for Netdata
    networking.firewall = { allowedTCPPorts = [ cfg.port ]; };

    # Ensure required system packages are available
    environment.systemPackages = with pkgs; [
      # curl for health checks
      curl
      # Additional monitoring tools
      htop
      iotop
      nethogs
    ];
  };
}
