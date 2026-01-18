{ config
, lib
, pkgs
, ...
}:

with lib;

let
  cfg = config.modules.services.dokploy;
in
{
  options.modules.services.dokploy = {
    enable = mkEnableOption "Dokploy worker node";

    user = mkOption {
      type = types.str;
      default = "dokploy";
      description = "User account for Dokploy SSH connections";
    };

    group = mkOption {
      type = types.str;
      default = "users";
      description = "Primary group for the Dokploy user";
    };

    dataDir = mkOption {
      type = types.path;
      default = /etc/dokploy;
      description = "Directory for Dokploy data and configurations";
    };

    authorizedKeys = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "SSH authorized keys for the Dokploy user";
    };

    initSwarm = mkOption {
      type = types.bool;
      default = true;
      description = "Initialize Docker Swarm on activation if not already active";
    };

    createNetwork = mkOption {
      type = types.bool;
      default = true;
      description = "Create dokploy-network overlay network on activation";
    };

    traefik = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Install and configure Traefik reverse proxy";
      };

      version = mkOption {
        type = types.str;
        default = "3.6.1";
        description = "Traefik version to use";
      };

      acmeEmail = mkOption {
        type = types.str;
        default = "admin@localhost.com";
        description = "Email for Let's Encrypt certificate registration";
      };
    };
  };

  config = mkIf cfg.enable {
    # Ensure Docker is enabled with swarm-compatible settings
    assertions = [
      {
        assertion = config.virtualisation.docker.enable or config.modules.services.virtualization.docker.enable or false;
        message = "Dokploy requires Docker to be enabled. Enable modules.services.virtualization.docker or virtualisation.docker.";
      }
    ];

    # Create the dokploy user
    users.users.${cfg.user} = {
      isNormalUser = true;
      description = "Dokploy deployment user";
      group = cfg.group;
      extraGroups = [ "docker" ];
      shell = pkgs.bash;
      openssh.authorizedKeys.keys = cfg.authorizedKeys;
    };

    # Create the directory structure using systemd-tmpfiles
    systemd.tmpfiles.rules = [
      # Main directory
      "d ${cfg.dataDir}                  0755 ${cfg.user} ${cfg.group} -"
      # Subdirectories
      "d ${cfg.dataDir}/applications     0755 ${cfg.user} ${cfg.group} -"
      "d ${cfg.dataDir}/compose          0755 ${cfg.user} ${cfg.group} -"
      "d ${cfg.dataDir}/logs             0755 ${cfg.user} ${cfg.group} -"
      "d ${cfg.dataDir}/monitoring       0755 ${cfg.user} ${cfg.group} -"
      "d ${cfg.dataDir}/registry         0755 ${cfg.user} ${cfg.group} -"
      "d ${cfg.dataDir}/schedules        0755 ${cfg.user} ${cfg.group} -"
      "d ${cfg.dataDir}/volume-backups   0755 ${cfg.user} ${cfg.group} -"
      # SSH directory with restricted permissions
      "d ${cfg.dataDir}/ssh              0700 ${cfg.user} ${cfg.group} -"
      # Traefik directories
      "d ${cfg.dataDir}/traefik                         0755 ${cfg.user} ${cfg.group} -"
      "d ${cfg.dataDir}/traefik/dynamic                 0755 ${cfg.user} ${cfg.group} -"
      "d ${cfg.dataDir}/traefik/dynamic/certificates    0755 ${cfg.user} ${cfg.group} -"
    ];

    # Activation script to initialize Swarm and create network
    system.activationScripts.dokploy-init = mkIf (cfg.initSwarm || cfg.createNetwork) {
      text = ''
        # Wait for Docker to be ready
        timeout=30
        while ! ${pkgs.docker}/bin/docker info >/dev/null 2>&1; do
          timeout=$((timeout - 1))
          if [ $timeout -le 0 ]; then
            echo "dokploy-init: Docker not ready, skipping initialization"
            exit 0
          fi
          sleep 1
        done

        ${optionalString cfg.initSwarm ''
          # Initialize Docker Swarm if not already active
          if ! ${pkgs.docker}/bin/docker info 2>/dev/null | grep -q "Swarm: active"; then
            echo "dokploy-init: Initializing Docker Swarm..."
            # Get the primary IP address
            ADVERTISE_ADDR=$(${pkgs.iproute2}/bin/ip route get 1 2>/dev/null | ${pkgs.gawk}/bin/awk '{print $7; exit}')
            if [ -n "$ADVERTISE_ADDR" ]; then
              ${pkgs.docker}/bin/docker swarm init --advertise-addr "$ADVERTISE_ADDR" || true
            else
              ${pkgs.docker}/bin/docker swarm init || true
            fi
          fi
        ''}

        ${optionalString cfg.createNetwork ''
          # Create dokploy-network if it doesn't exist
          if ! ${pkgs.docker}/bin/docker network ls | grep -q "dokploy-network"; then
            echo "dokploy-init: Creating dokploy-network..."
            ${pkgs.docker}/bin/docker network create --driver overlay --attachable dokploy-network || true
          fi
        ''}
      '';
      deps = [ "setupSecrets" ];
    };

    # Traefik configuration files
    environment.etc = mkIf cfg.traefik.enable {
      "dokploy/traefik/traefik.yml" = {
        user = cfg.user;
        group = cfg.group;
        mode = "0644";
        text = ''
          providers:
            swarm:
              exposedByDefault: false
              watch: true
            docker:
              exposedByDefault: false
              watch: true
              network: dokploy-network
            file:
              directory: /etc/dokploy/traefik/dynamic
              watch: true
          entryPoints:
            web:
              address: :80
            websecure:
              address: :443
              http3:
                advertisedPort: 443
              http:
                tls:
                  certResolver: letsencrypt
          api:
            insecure: true
          certificatesResolvers:
            letsencrypt:
              acme:
                email: ${cfg.traefik.acmeEmail}
                storage: /etc/dokploy/traefik/dynamic/acme.json
                httpChallenge:
                  entryPoint: web
        '';
      };

      "dokploy/traefik/dynamic/middlewares.yml" = {
        user = cfg.user;
        group = cfg.group;
        mode = "0644";
        text = ''
          http:
            middlewares:
              redirect-to-https:
                redirectScheme:
                  scheme: https
                  permanent: true
        '';
      };
    };

    # Traefik container service
    virtualisation.oci-containers.containers = mkIf cfg.traefik.enable {
      dokploy-traefik = {
        image = "traefik:v${cfg.traefik.version}";
        autoStart = true;
        extraOptions = [
          "--network=dokploy-network"
        ];
        ports = [
          "80:80"
          "443:443"
          "443:443/udp"
          "8080:8080"
        ];
        volumes = [
          "/etc/dokploy/traefik/traefik.yml:/etc/traefik/traefik.yml:ro"
          "/etc/dokploy/traefik/dynamic:/etc/dokploy/traefik/dynamic"
          "/var/run/docker.sock:/var/run/docker.sock:ro"
        ];
      };
    };

    # Open firewall ports if traefik is enabled
    networking.firewall = mkIf cfg.traefik.enable {
      allowedTCPPorts = [ 80 443 8080 ];
      allowedUDPPorts = [ 443 ];
    };
  };
}
