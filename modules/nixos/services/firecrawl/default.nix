{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.modules.services.firecrawl;
  composeFile = pkgs.writeText "firecrawl-docker-compose.yaml" ''
    name: firecrawl

    x-common-env: &common-env
      REDIS_URL: redis://redis:6379
      REDIS_RATE_LIMIT_URL: redis://redis:6379
      PLAYWRIGHT_MICROSERVICE_URL: http://playwright-service:3000/scrape
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: postgres
      POSTGRES_HOST: nuq-postgres
      POSTGRES_PORT: 5432
      USE_DB_AUTHENTICATION: "false"
      NUM_WORKERS_PER_QUEUE: "4"
      CRAWL_CONCURRENT_REQUESTS: "6"
      MAX_CONCURRENT_JOBS: "3"
      BROWSER_POOL_SIZE: "3"
      OPENAI_API_KEY: local
      OPENAI_BASE_URL: ${cfg.openaiBaseUrl}
      MODEL_NAME: ${cfg.model}
      BULL_AUTH_KEY: local
      LOGGING_LEVEL: info

    services:
      playwright-service:
        image: ghcr.io/firecrawl/playwright-service:latest
        environment:
          PORT: 3000
          MAX_CONCURRENT_PAGES: "6"
        networks:
          - backend
        restart: unless-stopped
        tmpfs:
          - /tmp/.cache:noexec,nosuid,size=1g

      api:
        image: ghcr.io/firecrawl/firecrawl:latest
        ulimits:
          nofile:
            soft: 65535
            hard: 65535
        networks:
          - backend
        extra_hosts:
          - "host.docker.internal:host-gateway"
        environment:
          <<: *common-env
          HOST: "0.0.0.0"
          PORT: 3002
          EXTRACT_WORKER_PORT: 3004
          WORKER_PORT: 3005
          NUQ_RABBITMQ_URL: amqp://rabbitmq:5672
          HARNESS_STARTUP_TIMEOUT_MS: "60000"
          ENV: local
        depends_on:
          redis:
            condition: service_started
          playwright-service:
            condition: service_started
          rabbitmq:
            condition: service_healthy
          nuq-postgres:
            condition: service_started
        ports:
          - "127.0.0.1:${toString cfg.port}:3002"
        command: node dist/src/harness.js --start-docker
        restart: unless-stopped

      redis:
        image: redis:alpine
        networks:
          - backend
        command: redis-server --bind 0.0.0.0
        restart: unless-stopped

      rabbitmq:
        image: rabbitmq:3-management
        networks:
          - backend
        command: rabbitmq-server
        healthcheck:
          test:
            - CMD
            - rabbitmq-diagnostics
            - -q
            - check_running
          interval: 5s
          timeout: 5s
          retries: 3
          start_period: 5s
        restart: unless-stopped

      nuq-postgres:
        image: ghcr.io/firecrawl/nuq-postgres:latest
        environment:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: postgres
        networks:
          - backend
        volumes:
          - nuq-postgres-data:/var/lib/postgresql/data
        restart: unless-stopped

    networks:
      backend:
        driver: bridge

    volumes:
      nuq-postgres-data:
  '';
in
{
  #============================================================================
  # OPTIONS
  #============================================================================
  options.modules.services.firecrawl = {
    enable = mkEnableOption "local Firecrawl web search and extraction service";

    port = mkOption {
      type = types.port;
      default = 4312;
      description = "Localhost port for the Firecrawl API.";
    };

    model = mkOption {
      type = types.str;
      default = config.modules.services.hermes-agent.model or "hermes-local";
      description = "OpenAI-compatible model name used by Firecrawl AI features.";
    };

    openaiBaseUrl = mkOption {
      type = types.str;
      default = "http://host.docker.internal:18080/v1";
      description = "OpenAI-compatible endpoint Firecrawl uses for AI extraction.";
    };

    llamaCppProxy = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Expose host-local llama.cpp to Firecrawl containers through the Docker bridge.";
      };

      bindAddress = mkOption {
        type = types.str;
        default = "172.20.0.1";
        description = "Docker bridge address used for the llama.cpp forwarding proxy.";
      };

      port = mkOption {
        type = types.port;
        default = 18080;
        description = "Docker-bridge port that forwards to the host-local llama.cpp server.";
      };

      target = mkOption {
        type = types.str;
        default = "127.0.0.1:8080";
        description = "Host-local llama.cpp target address.";
      };
    };
  };

  #============================================================================
  # CONFIG
  #============================================================================
  config = mkIf cfg.enable {
    virtualisation.oci-containers.backend = mkDefault "docker";

    environment.systemPackages = [ pkgs.docker-compose ];

    systemd.tmpfiles.rules = [
      "d /var/lib/firecrawl 0750 root root -"
    ];

    systemd.services.firecrawl-llamacpp-proxy = mkIf cfg.llamaCppProxy.enable {
      description = "Firecrawl llama.cpp bridge proxy";
      after = [ "docker.service" ];
      requires = [ "docker.service" ];
      wantedBy = [ "firecrawl.service" ];

      serviceConfig = {
        ExecStart = ''
          ${pkgs.socat}/bin/socat TCP-LISTEN:${toString cfg.llamaCppProxy.port},bind=${cfg.llamaCppProxy.bindAddress},reuseaddr,fork TCP:${cfg.llamaCppProxy.target}
        '';
        Restart = "always";
        RestartSec = "2s";
      };
    };

    systemd.services.firecrawl = {
      description = "Local Firecrawl stack";
      after = [
        "docker.service"
        "network-online.target"
      ]
      ++ optional cfg.llamaCppProxy.enable "firecrawl-llamacpp-proxy.service";
      requires = [
        "docker.service"
      ]
      ++ optional cfg.llamaCppProxy.enable "firecrawl-llamacpp-proxy.service";
      wantedBy = [ "multi-user.target" ];

      path = [
        config.virtualisation.docker.package
        pkgs.docker-compose
      ];

      serviceConfig = {
        Type = "exec";
        WorkingDirectory = "/var/lib/firecrawl";
        ExecStart = "${pkgs.docker-compose}/bin/docker-compose -f ${composeFile} up --remove-orphans";
        ExecStop = "${pkgs.docker-compose}/bin/docker-compose -f ${composeFile} down";
        Restart = "always";
        RestartSec = "10s";
        TimeoutStartSec = "10min";
        TimeoutStopSec = "2min";
      };
    };
  };
}
