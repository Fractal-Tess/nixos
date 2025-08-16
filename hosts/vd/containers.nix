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

    # Port configuration - Radarr web UI runs on port 7878
    ports = [{
      host = 7878;
      container = 7878;
      protocol = "tcp";
      openfw = true;
    }];

    # Volume mounts for Radarr
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
        host = "/mnt/vault/media/active-torrents";
        container = "/downloads";
      }
    ];

    # Environment variables for user permissions and timezone
    environment = {
      PUID = "1000";
      PGID = "1000";
      TZ = "UTC";
    };

    # Container behavior
    autoStart = true;

    # Extra options for better container operation
    extraOptions = [ "--security-opt=no-new-privileges:false" ];
  };

  # Nginx container on port 8089
  nginxContainer = ociLib.createOciContainer {
    name = "nginx";
    image = "nginx";
    tag = "latest";

    # Port configuration - Nginx runs on port 8089
    ports = [{
      host = 8089;
      container = 80;
      protocol = "tcp";
      openfw = true;
    }];

    # Volume mounts for Nginx
    volumes = [
      {
        host = "/var/lib/nginx/html";
        container = "/usr/share/nginx/html";
      }
      {
        host = "/var/lib/nginx/conf";
        container = "/etc/nginx/conf.d";
        options = "ro";
      }
    ];

    # Container behavior
    autoStart = true;

    # Extra options for better container operation
    extraOptions = [ ];
  };

  # Merge both container configurations
in nginxContainer // radarrContainer
