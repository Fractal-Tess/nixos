# configuration.nix
{ config, pkgs, lib, ... }:

let
  ociLib = import ./oci-container.nix { inherit lib pkgs; };

  # Radarr container configuration
  # Based on linuxserver/radarr Docker image
  # Web UI accessible at http://your-ip:7878
  radarrContainer = ociLib.createOciContainer {
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
  jellyfinContainer = ociLib.createOciContainer {
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
      # NVIDIA-specific environment variables for hardware acceleration
      NVIDIA_VISIBLE_DEVICES = "all";
      NVIDIA_DRIVER_CAPABILITIES = "compute,video,utility";
    };

    # Container behavior
    autoStart = true;

    # Extra options for hardware acceleration and network discovery
    extraOptions = [
      # Network mode for better discovery
      "--network=host"
      # Security option for GPU access
      "--security-opt=no-new-privileges:false"
      # NVIDIA GPU acceleration using CDI (Container Device Interface)
      "--device=nvidia.com/gpu=all"
      # Intel/AMD GPU acceleration (fallback)
      "--device=/dev/dri:/dev/dri"
      "--device=/dev/video0:/dev/video0"
    ];
  };

  # Netdata container configuration
  netdataContainer = ociLib.createOciContainer {
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
        host = "/var/lib/netdata/config";
        container = "/etc/netdata";
      }
      {
        host = "/var/lib/netdata/lib";
        container = "/var/lib/netdata";
      }
      {
        host = "/var/lib/netdata/cache";
        container = "/var/cache/netdata";
      }
    ];

    # Container behavior
    autoStart = true;

    # Extra options for system monitoring
    extraOptions =
      [ "--cap-add=SYS_PTRACE" "--security-opt=apparmor=unconfined" ];
  };

  # Portainer container configuration
  portainerContainer = ociLib.createOciContainer {
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
        host = "/run/user/1000/docker.sock";
        container = "/var/run/docker.sock";
      }
    ];

    # Container behavior
    autoStart = true;

    # Extra options for Docker socket access
    extraOptions = [ ];
  };

  # Jackett container configuration
  jackettContainer = ociLib.createOciContainer {
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
    volumes = [{
      host = "/var/lib/jackett/config";
      container = "/config";
    }];

    # Environment variables for user permissions and timezone
    environment = {
      PUID = "1000";
      PGID = "1000";
      TZ = "UTC";
    };

    # Container behavior
    autoStart = true;

    # Extra options
    extraOptions = [ "--network=host" ];
  };

  # qBittorrent container
  qbittorrentContainer = ociLib.createOciContainer {
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
      WEBUI_PORT = "8080";
    };
    user = {
      uid = 1000;
      gid = 1000;
    };
    autoStart = true;
    # Extra options
    extraOptions = [ "--network=host" ];
  };

  # Sonarr container
  sonarrContainer = ociLib.createOciContainer {
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
  jellyseerrContainer = ociLib.createOciContainer {
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
