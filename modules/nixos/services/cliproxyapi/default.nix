{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.modules.services.cliproxyapi;
  stateDir = "/var/lib/cliproxyapi";
  envFile = "${stateDir}/dashboard.env";
  configFile = "${stateDir}/config.yaml";
  composeFile = pkgs.writeText "cliproxyapi-compose.yaml" ''
    services:
      proxy:
        image: eceasy/cli-proxy-api@sha256:2d402a3edfbfa0612d7694345f7a05008fe8ce1915fde00ec9adb82afeb370c9
        environment:
          MANAGEMENT_PASSWORD: "''${MANAGEMENT_API_KEY}"
        ports:
          - "${cfg.listenAddress}:${toString cfg.proxyPort}:8317"
          - "${cfg.listenAddress}:1455:1455"
          - "${cfg.listenAddress}:8085:8085"
          - "${cfg.listenAddress}:11451:11451"
          - "${cfg.listenAddress}:51121:51121"
          - "${cfg.listenAddress}:54545:54545"
        volumes:
          - ${configFile}:/CLIProxyAPI/config.yaml
          - ${stateDir}/auth:/root/.cli-proxy-api
        restart: unless-stopped
        logging: &default-logging
          driver: json-file
          options:
            max-size: 10m
            max-file: "3"

      postgres:
        image: postgres@sha256:57c72fd2a128e416c7fcc499958864df5301e940bca0a56f58fddf30ffc07777
        cpus: "0.5"
        mem_limit: 256m
        mem_reservation: 64m
        environment:
          POSTGRES_DB: cliproxyapi
          POSTGRES_USER: cliproxyapi
          POSTGRES_PASSWORD: "''${POSTGRES_PASSWORD}"
          TZ: UTC
        volumes:
          - postgres-data:/var/lib/postgresql/data
        healthcheck:
          test:
            - CMD-SHELL
            - pg_isready -U cliproxyapi -d cliproxyapi
          interval: 10s
          timeout: 5s
          retries: 5
          start_period: 10s
        restart: unless-stopped
        logging: *default-logging

      dashboard:
        image: ghcr.io/itsmylife44/cliproxyapi-dashboard/dashboard@sha256:8d6ac25c48cbc7510ceecda07238e64efa1f42c383df25ea5f7878f0d951a762
        cpus: "1.0"
        mem_limit: 512m
        mem_reservation: 128m
        ports:
          - "${cfg.listenAddress}:${toString cfg.dashboardPort}:3000"
        environment:
          DATABASE_URL: "postgresql://cliproxyapi:''${POSTGRES_PASSWORD}@postgres:5432/cliproxyapi"
          CLIPROXYAPI_MANAGEMENT_URL: http://proxy:8317/v0/management
          MANAGEMENT_API_KEY: "''${MANAGEMENT_API_KEY}"
          JWT_SECRET: "''${JWT_SECRET}"
          NODE_ENV: production
          API_URL: "http://${cfg.publicHostname}:${toString cfg.proxyPort}"
          DASHBOARD_URL: "http://${cfg.publicHostname}:${toString cfg.dashboardPort}"
          CLIPROXYAPI_CONTAINER_NAME: cliproxyapi-proxy-1
          ALLOW_LOCAL_PROVIDER_URLS: "true"
        volumes:
          - dashboard-backups:/app/backups
        depends_on:
          postgres:
            condition: service_healthy
          proxy:
            condition: service_started
        healthcheck:
          test:
            - CMD
            - node
            - -e
            - "fetch('http://localhost:3000/api/health').then(r=>{if(!r.ok)process.exit(1)}).catch(()=>process.exit(1))"
          interval: 15s
          timeout: 10s
          retries: 5
          start_period: 40s
        restart: unless-stopped
        logging: *default-logging

    volumes:
      postgres-data:
      dashboard-backups:
  '';

  dashboardStartScript = pkgs.writeShellScript "cliproxyapi-dashboard-start" ''
    set -euo pipefail

    if [[ ! -s ${envFile} ]]; then
      umask 077
      temporary_env="$(${pkgs.coreutils}/bin/mktemp ${envFile}.XXXXXX)"
      postgres_password="$(${pkgs.openssl}/bin/openssl rand -hex 32)"
      management_api_key="$(${pkgs.openssl}/bin/openssl rand -hex 32)"
      jwt_secret="$(${pkgs.openssl}/bin/openssl rand -hex 32)"
      client_api_key="$(${pkgs.openssl}/bin/openssl rand -hex 32)"
      ${pkgs.coreutils}/bin/printf 'POSTGRES_PASSWORD=%s\nMANAGEMENT_API_KEY=%s\nJWT_SECRET=%s\nCLIENT_API_KEY=%s\n' \
        "$postgres_password" "$management_api_key" "$jwt_secret" "$client_api_key" > "$temporary_env"
      ${pkgs.coreutils}/bin/install -m 0600 "$temporary_env" ${envFile}
      ${pkgs.coreutils}/bin/rm -f "$temporary_env"
    fi

    set -a
    source ${envFile}
    set +a

    if [[ ! -s ${configFile} ]]; then
      umask 077
      temporary_config="$(${pkgs.coreutils}/bin/mktemp ${configFile}.XXXXXX)"
      ${pkgs.coreutils}/bin/cat > "$temporary_config" <<EOF
    host: 0.0.0.0
    port: 8317
    auth-dir: /root/.cli-proxy-api
    api-keys:
      - $CLIENT_API_KEY
    usage-statistics-enabled: true
    remote-management:
      allow-remote: true
      secret-key: ""
      disable-control-panel: true
    EOF
      ${pkgs.coreutils}/bin/install -m 0600 "$temporary_config" ${configFile}
      ${pkgs.coreutils}/bin/rm -f "$temporary_config"
    fi

    ${pkgs.docker-compose}/bin/docker-compose -f ${composeFile} --env-file ${envFile} up --detach --remove-orphans --wait --wait-timeout 600
    ${pkgs.systemd}/bin/systemd-notify --ready
    services="$(${pkgs.docker-compose}/bin/docker-compose -f ${composeFile} --env-file ${envFile} config --services)"
    exec ${pkgs.docker-compose}/bin/docker-compose -f ${composeFile} --env-file ${envFile} wait $services
  '';

  apiKeyFile = "${stateDir}/api-key";
  proxyStartScript = pkgs.writeShellScript "cliproxyapi-proxy-start" ''
    set -euo pipefail

    for _ in $(${pkgs.coreutils}/bin/seq 1 120); do
      if ${pkgs.iproute2}/bin/ip -4 address show dev ${escapeShellArg cfg.netbirdInterface} \
        | ${pkgs.gnugrep}/bin/grep -Fq ${escapeShellArg " ${cfg.listenAddress}/"}; then
        break
      fi
      ${pkgs.coreutils}/bin/sleep 1
    done

    ${pkgs.iproute2}/bin/ip -4 address show dev ${escapeShellArg cfg.netbirdInterface} \
      | ${pkgs.gnugrep}/bin/grep -Fq ${escapeShellArg " ${cfg.listenAddress}/"}

    if [[ ! -s ${apiKeyFile} ]]; then
      umask 077
      temporary_key="$(${pkgs.coreutils}/bin/mktemp ${apiKeyFile}.XXXXXX)"
      ${pkgs.openssl}/bin/openssl rand -hex 32 > "$temporary_key"
      ${pkgs.coreutils}/bin/install -m 0600 "$temporary_key" ${apiKeyFile}
      ${pkgs.coreutils}/bin/rm -f "$temporary_key"
    fi
    ${pkgs.coreutils}/bin/chmod 0600 ${apiKeyFile}

    client_api_key="$(${pkgs.coreutils}/bin/tr -d '\n' < ${apiKeyFile})"
    umask 077
    temporary_config="$(${pkgs.coreutils}/bin/mktemp ${configFile}.XXXXXX)"
    ${pkgs.coreutils}/bin/cat > "$temporary_config" <<EOF
    host: ${cfg.listenAddress}
    port: ${toString cfg.proxyPort}
    auth-dir: ${stateDir}/auth
    api-keys:
      - $client_api_key
    remote-management:
      allow-remote: false
      disable-control-panel: true
    oauth-model-alias:
      codex:
        - name: gpt-5.6-sol
          alias: gpt-5.6-luna
          force-mapping: true
    EOF
    ${pkgs.coreutils}/bin/install -m 0600 "$temporary_config" ${configFile}
    ${pkgs.coreutils}/bin/rm -f "$temporary_config"

    exec ${pkgs.cliproxyapi}/bin/cliproxyapi -config ${configFile}
  '';
in
{
  options.modules.services.cliproxyapi = {
    enable = mkEnableOption "NetBird-accessible CLIProxyAPI and management dashboard";

    proxyOnly = mkOption {
      type = types.bool;
      default = false;
      description = "Run only the native OpenAI-compatible proxy without the dashboard stack.";
    };

    netbirdInterface = mkOption {
      type = types.str;
      default = "wt0";
      description = "NetBird interface permitted through the firewall and required for the listen address.";
    };

    listenAddress = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Address on which CLIProxyAPI, its dashboard, and OAuth callbacks listen.";
    };

    publicHostname = mkOption {
      type = types.str;
      default = "localhost";
      description = "Hostname advertised to dashboard clients.";
    };

    proxyPort = mkOption {
      type = types.port;
      default = 38317;
      description = "OpenAI-compatible CLIProxyAPI port.";
    };

    dashboardPort = mkOption {
      type = types.port;
      default = 38300;
      description = "CLIProxyAPI dashboard port.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      systemd.tmpfiles.rules = [
        "d ${stateDir} 0700 root root -"
        "d ${stateDir}/auth 0700 root root -"
      ];

      networking.firewall.interfaces.${cfg.netbirdInterface}.allowedTCPPorts = [ cfg.proxyPort ];
    }

    (mkIf cfg.proxyOnly {
      systemd.services.cliproxyapi = {
        description = "NetBird-only CLIProxyAPI proxy";
        after = [
          "netbird.service"
          "network-online.target"
        ];
        requires = [ "netbird.service" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          WorkingDirectory = stateDir;
          ExecStart = proxyStartScript;
          Restart = "on-failure";
          RestartSec = "10s";
          TimeoutStartSec = "3min";
          UMask = "0077";

          CapabilityBoundingSet = "";
          LockPersonality = true;
          NoNewPrivileges = true;
          PrivateDevices = true;
          PrivateTmp = true;
          ProtectClock = true;
          ProtectControlGroups = true;
          ProtectHome = true;
          ProtectHostname = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProtectSystem = "strict";
          ReadWritePaths = [ stateDir ];
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
            "AF_UNIX"
          ];
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          SystemCallArchitectures = "native";
        };
      };
    })

    (mkIf (!cfg.proxyOnly) {
      virtualisation.oci-containers.backend = mkDefault "docker";
      environment.systemPackages = [ pkgs.docker-compose ];

      system.build.cliproxyapiCompose = composeFile;

      networking.firewall.interfaces.${cfg.netbirdInterface}.allowedTCPPorts = [
        1455
        8085
        11451
        cfg.dashboardPort
        51121
        54545
      ];

      systemd.services.cliproxyapi = {
        description = "CLIProxyAPI and management dashboard";
        after = [
          "docker.service"
          "network-online.target"
        ];
        requires = [ "docker.service" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];

        path = [
          config.virtualisation.docker.package
          pkgs.docker-compose
        ];

        serviceConfig = {
          Type = "notify";
          NotifyAccess = "all";
          WorkingDirectory = stateDir;
          ExecStart = dashboardStartScript;
          ExecStop = "${pkgs.docker-compose}/bin/docker-compose -f ${composeFile} --env-file ${envFile} down";
          Restart = "on-failure";
          RestartSec = "10s";
          TimeoutStartSec = "15min";
          TimeoutStopSec = "2min";
        };
      };
    })
  ]);
}
