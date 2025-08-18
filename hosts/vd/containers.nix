# configuration.nix
{ config, pkgs, lib, createOciContainer, ... }:

let
  # Radarr container configuration
  # Based on linuxserver/radarr Docker image
  # Web UI accessible at http://your-ip:7878
  radarrContainer = createOciContainer {
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
    user = {
      uid = 1000;
      gid = 1000;
    };
    autoStart = true;
    # Extra options
    extraOptions = [ "--network=host" ];
  };

  # Jellyfin container configuration
  jellyfinContainer = createOciContainer {
    name = "jellyfin";
    image = "lscr.io/linuxserver/jellyfin";
    tag = "latest";

    # Port configuration - Jellyfin web UI and discovery ports
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

    # Volume mounts for Jellyfin
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

    # Environment variables for user permissions, timezone, and GPU support
    environment = {
      PUID = "1000";
      PGID = "1000";
      TZ = "UTC";
    };

    # User configuration for file permissions
    user = {
      uid = 1000;
      gid = 1000;
    };

    # Container behavior
    autoStart = true;

    # Extra options for GPU support and networking
    extraOptions = [
      "--network=host"
      "--device=/dev/dri:/dev/dri"
      "--security-opt=no-new-privileges:false"
    ];
  };

  # Netdata container configuration
  netdataContainer = createOciContainer {
    name = "netdata";
    image = "netdata/netdata";
    tag = "latest";

    # Port configuration - Netdata web UI runs on port 19999
    ports = [{
      host = 19999;
      container = 19999;
      protocol = "tcp";
      openfw = true;
    }];

    # Volume mounts for Netdata
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

    # Container behavior
    autoStart = true;

    # Extra options for system monitoring
    extraOptions = [
      "--network=host"
      "--pid=host"
      "--cap-add=SYS_PTRACE"
      "--security-opt=apparmor=unconfined"
    ];
  };

  # Portainer container configuration
  portainerContainer = createOciContainer {
    name = "portainer";
    image = "portainer/portainer-ce";
    tag = "latest";

    # Port configuration - Portainer web UI runs on port 9000
    ports = [{
      host = 9000;
      container = 9000;
      protocol = "tcp";
      openfw = true;
    }];

    # Volume mounts for Portainer
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

    # Container behavior
    autoStart = true;

    # Extra options for Docker socket access
    extraOptions = [ "--network=host" ];
  };

  # Jackett container configuration
  jackettContainer = createOciContainer {
    name = "jackett";
    image = "lscr.io/linuxserver/jackett";
    tag = "latest";

    # Port configuration - Jackett web UI runs on port 9117
    ports = [{
      host = 9117;
      container = 9117;
      protocol = "tcp";
      openfw = true;
    }];

    # Volume mounts for Jackett
    volumes = [
      {
        host = "/var/lib/jackett/config";
        container = "/config";
      }
      {
        host = "/mnt/vault/media/downloads";
        container = "/downloads";
      }
    ];

    # Environment variables
    environment = {
      PUID = "1000";
      PGID = "1000";
      TZ = "UTC";
    };

    # User configuration
    user = {
      uid = 1000;
      gid = 1000;
    };

    # Container behavior
    autoStart = true;

    # Extra options
    extraOptions = [ "--network=host" ];
  };

  # qBittorrent container configuration
  qbittorrentContainer = createOciContainer {
    name = "qbittorrent";
    image = "lscr.io/linuxserver/qbittorrent";
    tag = "latest";

    # Port configuration - qBittorrent web UI and BitTorrent ports
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

    # Volume mounts for qBittorrent
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

    # Environment variables
    environment = {
      PUID = "1000";
      PGID = "1000";
      TZ = "UTC";
    };

    # User configuration
    user = {
      uid = 1000;
      gid = 1000;
    };

    # Container behavior
    autoStart = true;

    # Extra options
    extraOptions = [ "--network=host" ];
  };

  # Sonarr container configuration
  sonarrContainer = createOciContainer {
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
    user = {
      uid = 1000;
      gid = 1000;
    };
    autoStart = true;
    # Extra options
    extraOptions = [ "--network=host" ];
  };

  # Jellyseerr container configuration
  jellyseerrContainer = createOciContainer {
    name = "jellyseerr";
    image = "fallenbagel/jellyseerr";
    tag = "latest";

    # Port configuration - Jellyseerr web UI runs on port 5055
    ports = [{
      host = 5055;
      container = 5055;
      protocol = "tcp";
      openfw = true;
    }];

    # Volume mounts for Jellyseerr
    volumes = [{
      host = "/var/lib/jellyseerr/config";
      container = "/app/config";
    }];

    # Container behavior
    autoStart = true;

    # Extra options
    extraOptions = [ "--network=host" ];
  };

in {
  # Combine all OCI container configurations
  virtualisation.oci-containers.containers =
    radarrContainer.virtualisation.oci-containers.containers
    // jellyfinContainer.virtualisation.oci-containers.containers
    // netdataContainer.virtualisation.oci-containers.containers
    // portainerContainer.virtualisation.oci-containers.containers
    // jackettContainer.virtualisation.oci-containers.containers
    // qbittorrentContainer.virtualisation.oci-containers.containers
    // sonarrContainer.virtualisation.oci-containers.containers
    // jellyseerrContainer.virtualisation.oci-containers.containers;

  # Firewall configuration - directly specify the ports that should be opened
  # Based on the container configurations with openfw = true
  networking.firewall = {
    # TCP ports for web UIs and services
    allowedTCPPorts = [
      7878 # Radarr
      8096 # Jellyfin web UI
      8920 # Jellyfin streaming
      19999 # Netdata
      9000 # Portainer
      9117 # Jackett
      8080 # qBittorrent web UI
      6881 # qBittorrent BitTorrent
      8989 # Sonarr
      5055 # Jellyseerr
    ];

    # UDP ports for discovery and streaming
    allowedUDPPorts = [
      7359 # Jellyfin discovery
      1900 # Jellyfin SSDP
      6881 # qBittorrent BitTorrent
    ];
  };
}
