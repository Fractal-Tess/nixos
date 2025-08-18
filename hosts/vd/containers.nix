# configuration.nix
{ config, pkgs, lib, createOciContainer, ... }:

let
  # Helper function to extract ports from container definitions
  extractFirewallPorts = containerDefs:
    let
      # Extract all ports with openfw = true from container definitions
      allPorts = lib.concatMap (containerDef:
        lib.optionals (containerDef ? ports)
        (lib.filter (port: port.openfw or false) containerDef.ports))
        containerDefs;

      # Separate TCP and UDP ports
      tcpPorts = lib.unique (lib.map (port: port.host)
        (lib.filter (port: port.protocol == "tcp") allPorts));
      udpPorts = lib.unique (lib.map (port: port.host)
        (lib.filter (port: port.protocol == "udp") allPorts));
    in {
      tcp = tcpPorts;
      udp = udpPorts;
    };

  # Container definitions with ports
  containerDefinitions = [
    # Radarr container configuration
    {
      name = "radarr";
      image = "lscr.io/linuxserver/radarr";
      tag = "latest";
      ports = [{
        host = 7878;
        container = 7878;
        protocol = "tcp";
        openfw = true;
      }];
      volumes = [
        {
          host = "/var/lib/radarr/config";
          container = "/config";
        }
        {
          host = "/mnt/vault/media/movies";
          container = "/movies";
        }
        {
          host = "/mnt/vault/media/downloads";
          container = "/downloads";
        }
      ];
      environment = {
        PUID = "1000";
        PGID = "1000";
        TZ = "UTC";
      };
      user = "1000:1000";
      autoStart = true;
      extraOptions = [ "--network=host" ];
    }

    # Jellyfin container configuration
    {
      name = "jellyfin";
      image = "lscr.io/linuxserver/jellyfin";
      tag = "latest";
      ports = [
        {
          host = 8096;
          container = 8096;
          protocol = "tcp";
          openfw = true;
        }
        {
          host = 8920;
          container = 8920;
          protocol = "tcp";
          openfw = true;
        }
        {
          host = 7359;
          container = 7359;
          protocol = "udp";
          openfw = true;
        }
        {
          host = 1900;
          container = 1900;
          protocol = "udp";
          openfw = true;
        }
      ];
      volumes = [
        {
          host = "/var/lib/jellyfin/config";
          container = "/config";
        }
        {
          host = "/var/lib/jellyfin/cache";
          container = "/cache";
        }
        {
          host = "/mnt/vault/media";
          container = "/media";
        }
      ];
      environment = {
        PUID = "1000";
        PGID = "1000";
        TZ = "UTC";
        # NVIDIA-specific environment variables for hardware acceleration
        NVIDIA_VISIBLE_DEVICES = "all";
        NVIDIA_DRIVER_CAPABILITIES = "compute,video,utility";
      };
      user = "1000:1000";
      autoStart = true;
      extraOptions = [
        "--network=host"
        # Intel GPU acceleration
        "--device=/dev/dri:/dev/dri"
        "--security-opt=no-new-privileges:false"
        # NVIDIA GPU acceleration
        "--device=nvidia.com/gpu=all"
        # Intel/AMD GPU acceleration
        "--device=/dev/video0:/dev/video0"
      ];
    }

    # Netdata container configuration
    {
      name = "netdata";
      image = "netdata/netdata";
      tag = "latest";
      ports = [{
        host = 19999;
        container = 19999;
        protocol = "tcp";
        openfw = true;
      }];
      volumes = [
        {
          host = "/var/lib/netdata";
          container = "/var/lib/netdata";
        }
        {
          host = "/etc/netdata";
          container = "/etc/netdata";
        }
        {
          host = "/proc";
          container = "/host/proc";
          options = "ro";
        }
        {
          host = "/sys";
          container = "/host/sys";
          options = "ro";
        }
      ];
      autoStart = true;
      extraOptions = [
        "--network=host"
        "--pid=host"
        "--cap-add=SYS_PTRACE"
        "--security-opt=apparmor=unconfined"
      ];
    }

    # Portainer container configuration
    {
      name = "portainer";
      image = "portainer/portainer-ce";
      tag = "latest";
      ports = [{
        host = 9000;
        container = 9000;
        protocol = "tcp";
        openfw = true;
      }];
      volumes = [
        {
          host = "/var/lib/portainer";
          container = "/data";
        }
        {
          host = "/var/run/docker.sock";
          container = "/var/run/docker.sock";
        }
      ];
      autoStart = true;
      extraOptions = [ "--network=host" ];
    }

    # Jackett container configuration
    {
      name = "jackett";
      image = "lscr.io/linuxserver/jackett";
      tag = "latest";
      ports = [{
        host = 9117;
        container = 9117;
        protocol = "tcp";
        openfw = true;
      }];
      volumes = [{
        host = "/var/lib/jackett/config";
        container = "/config";
      }];
      environment = {
        PUID = "1000";
        PGID = "1000";
        TZ = "UTC";
      };
      autoStart = true;
      extraOptions = [ "--network=host" ];
    }

    # qBittorrent container configuration
    {
      name = "qbittorrent";
      image = "lscr.io/linuxserver/qbittorrent";
      tag = "latest";
      ports = [
        {
          host = 8080;
          container = 8080;
          protocol = "tcp";
          openfw = true;
        }
        {
          host = 6881;
          container = 6881;
          protocol = "tcp";
          openfw = true;
        }
        {
          host = 6881;
          container = 6881;
          protocol = "udp";
          openfw = true;
        }
      ];
      volumes = [
        {
          host = "/var/lib/qbittorrent/config";
          container = "/config";
        }
        {
          host = "/mnt/vault/media/downloads";
          container = "/downloads";
        }
      ];
      environment = {
        PUID = "1000";
        PGID = "1000";
        TZ = "UTC";
      };
      user = "1000:1000";
      autoStart = true;
      extraOptions = [ "--network=host" ];
    }

    # Sonarr container configuration
    {
      name = "sonarr";
      image = "lscr.io/linuxserver/sonarr";
      tag = "latest";
      ports = [{
        host = 8989;
        container = 8989;
        protocol = "tcp";
        openfw = true;
      }];
      volumes = [
        {
          host = "/var/lib/sonarr/config";
          container = "/config";
        }
        {
          host = "/mnt/vault/media/tvshows";
          container = "/tv";
        }
        {
          host = "/mnt/vault/media/downloads";
          container = "/downloads";
        }
      ];
      environment = {
        PUID = "1000";
        PGID = "1000";
        TZ = "UTC";
      };
      user = "1000:1000";
      autoStart = true;
      extraOptions = [ "--network=host" ];
    }

    # Jellyseerr container configuration
    {
      name = "jellyseerr";
      image = "fallenbagel/jellyseerr";
      tag = "latest";
      ports = [{
        host = 5055;
        container = 5055;
        protocol = "tcp";
        openfw = true;
      }];
      volumes = [{
        host = "/var/lib/jellyseerr/config";
        container = "/app/config";
      }];
      environment = {
        PUID = "1000";
        PGID = "1000";
        TZ = "UTC";
      };
      autoStart = true;
      extraOptions = [ "--network=host" ];
    }
  ];

  # Create containers from definitions
  radarrContainer = createOciContainer (lib.elemAt containerDefinitions 0);
  jellyfinContainer = createOciContainer (lib.elemAt containerDefinitions 1);
  netdataContainer = createOciContainer (lib.elemAt containerDefinitions 2);
  portainerContainer = createOciContainer (lib.elemAt containerDefinitions 3);
  jackettContainer = createOciContainer (lib.elemAt containerDefinitions 4);
  qbittorrentContainer = createOciContainer (lib.elemAt containerDefinitions 5);
  sonarrContainer = createOciContainer (lib.elemAt containerDefinitions 6);
  jellyseerrContainer = createOciContainer (lib.elemAt containerDefinitions 7);

  # Combine all OCI container configurations
  allContainers = radarrContainer.virtualisation.oci-containers.containers
    // jellyfinContainer.virtualisation.oci-containers.containers
    // netdataContainer.virtualisation.oci-containers.containers
    // portainerContainer.virtualisation.oci-containers.containers
    // jackettContainer.virtualisation.oci-containers.containers
    // qbittorrentContainer.virtualisation.oci-containers.containers
    // sonarrContainer.virtualisation.oci-containers.containers
    // jellyseerrContainer.virtualisation.oci-containers.containers;

  # Automatically extract firewall ports from container definitions
  firewallPorts = extractFirewallPorts containerDefinitions;

in {
  # Combine all OCI container configurations
  virtualisation.oci-containers.containers = allContainers;

  # Firewall configuration - automatically generated from container port mappings
  # Only ports with openfw = true will be opened
  networking.firewall = {
    # TCP ports automatically extracted from containers with openfw = true
    allowedTCPPorts = firewallPorts.tcp;

    # UDP ports automatically extracted from containers with openfw = true
    allowedUDPPorts = firewallPorts.udp;
  };
}
