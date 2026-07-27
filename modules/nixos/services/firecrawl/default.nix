{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.modules.services.firecrawl;

  # Pinned multi-architecture image indexes from 2026-07-27.
  firecrawlImage = "ghcr.io/firecrawl/firecrawl@sha256:d2fe554a1a723d95f3af3ceb4146db5765efaba7fb1b1850f8fd2713b11da7f6";
  playwrightImage = "ghcr.io/firecrawl/playwright-service@sha256:8c50add7293201e575110e6c7489fa383a9dfc46f168936526a458e06ffc5c28";
  camofoxImage = "ghcr.io/jo-inc/camofox-browser@sha256:64b30ffdbbc4ae0e28200a66dfbd6f55ac4188229eb34ef769afcf7be40faa6e";
  camofoxRelease = pkgs.fetchzip {
    url = "https://github.com/daijro/camoufox/releases/download/v152.0.4-beta.28/camoufox-152.0.4-beta.28-lin.x86_64.zip";
    hash = "sha256-lWKkapB9Dwg/VL6McP/4eYxc4jmwBXDHXxTnvqbYHsA=";
    stripRoot = false;
  };
  camofoxVersion = pkgs.writeText "camoufox-version.json" ''
    {"version":"152.0.4","release":"beta.28"}
  '';
  camofoxBundle = pkgs.runCommand "camoufox-152.0.4-beta.28" { } ''
    mkdir -p "$out"
    cp -a ${camofoxRelease}/. "$out/"
    chmod u+w "$out"
    cp ${camofoxVersion} "$out/version.json"
  '';
  postgresImage = "ghcr.io/firecrawl/nuq-postgres@sha256:aed86f62858f29bd971abddcdeb301c12888098d2cf5d33c1ba42b053bc460f6";
  redisImage = "redis@sha256:8096655e437712b07503796fb64d81359256cfcff0ab29d95a7da72863786efb";
  codexProxyImage = "eceasy/cli-proxy-api@sha256:2d402a3edfbfa0612d7694345f7a05008fe8ce1915fde00ec9adb82afeb370c9";

  codexProxyConfig = pkgs.writeText "firecrawl-codex-proxy.yaml" ''
    host: 0.0.0.0
    port: 8317
    auth-dir: /root/.cli-proxy-api
  '';

  indentYaml =
    indentation: text:
    concatStringsSep "\n" (map (line: "${indentation}${line}") (splitString "\n" text));

  playwrightService = ''
    playwright-service:
      image: ${playwrightImage}
      environment:
        PORT: 3000
        MAX_CONCURRENT_PAGES: "3"
      networks:
        - backend
      restart: unless-stopped
      logging: *default-logging
      tmpfs:
        - /tmp/.cache:noexec,nosuid,size=1g
  '';

  camofoxService = ''
    # Private Firecrawl-compatible Camoufox browser backend. Set
    # modules.services.firecrawl.camofox.enable=false to roll back to Playwright.
    camofox-scrape:
      image: ${camofoxImage}
      init: true
      user: "1000:1000"
      read_only: true
      cap_drop:
        - ALL
      security_opt:
        - no-new-privileges:true
      cpus: "2.0"
      mem_limit: 3g
      pids_limit: 256
      ulimits:
        nofile:
          soft: 4096
          hard: 4096
      command:
        - node
        - /app/firecrawl-scrape.mjs
      environment:
        PORT: "3000"
        MAX_CONCURRENT_PAGES: "3"
        MAX_QUEUED_PAGES: "6"
        NODE_OPTIONS: --max-old-space-size=256
        HOME: /tmp/home
        XDG_CACHE_HOME: /tmp/home/.cache
        CAMOUFOX_EXECUTABLE: /opt/camoufox/camoufox-bin
      volumes:
        - ${./camofox-scrape.mjs}:/app/firecrawl-scrape.mjs:ro
        - ${camofoxBundle}:/opt/camoufox:ro
      networks:
        - backend
      healthcheck:
        test:
          - CMD
          - curl
          - --fail
          - --silent
          - http://127.0.0.1:3000/health
        interval: 15s
        timeout: 5s
        retries: 12
        start_period: 45s
      shm_size: 2gb
      tmpfs:
        - /tmp:rw,nosuid,nodev,mode=1777,size=1g
      restart: unless-stopped
      logging: *default-logging
  '';

  composeFile = pkgs.writeText "firecrawl-compose.yaml" ''
        name: firecrawl

        x-common-env: &common-env
          REDIS_URL: redis://redis:6379
          REDIS_RATE_LIMIT_URL: redis://redis:6379
          PLAYWRIGHT_MICROSERVICE_URL: ${
            if cfg.camofox.enable then
              "http://camofox-scrape:3000/scrape"
            else
              "http://playwright-service:3000/scrape"
          }
          NUQ_DATABASE_URL: postgresql://postgres:postgres@nuq-postgres:5432/postgres
          NUQ_DATABASE_URL_LISTEN: postgresql://postgres:postgres@nuq-postgres:5432/postgres
          NUQ_WAIT_MODE: listen
          USE_DB_AUTHENTICATION: "false"
          ENV: local
          LOGGING_LEVEL: info
          NUM_WORKERS_PER_QUEUE: "1"
          CRAWL_CONCURRENT_REQUESTS: "3"
          MAX_CONCURRENT_JOBS: "2"
          BROWSER_POOL_SIZE: "2"
    ${optionalString cfg.llm.enable "      OPENAI_BASE_URL: http://codex-proxy:8317/v1\n      OPENAI_API_KEY: local-firecrawl\n      MODEL_NAME: ${cfg.llm.model}"}

        x-default-logging: &default-logging
          driver: json-file
          options:
            max-size: 10m
            max-file: "3"
            compress: "true"

        x-firecrawl-service: &firecrawl-service
          image: ${firecrawlImage}
          networks:
            - backend
          environment:
            <<: *common-env
          depends_on:
            redis:
              condition: service_healthy
            nuq-postgres:
              condition: service_healthy
    ${
      if cfg.camofox.enable then
        "        camofox-scrape:\n          condition: service_healthy"
      else
        "        playwright-service:\n          condition: service_started"
    }
    ${optionalString cfg.llm.enable "        codex-proxy:\n          condition: service_started"}
          restart: unless-stopped
          logging: *default-logging

        services:
    ${optionalString cfg.llm.enable "      codex-proxy:\n        image: ${codexProxyImage}\n        networks:\n          - backend\n        volumes:\n          - ${codexProxyConfig}:/CLIProxyAPI/config.yaml:ro\n          - /var/lib/firecrawl/codex-auth:/root/.cli-proxy-api\n        restart: unless-stopped\n        logging: *default-logging"}

    ${indentYaml "      " (if cfg.camofox.enable then camofoxService else playwrightService)}

          api:
            <<: *firecrawl-service
            environment:
              <<: *common-env
              HOST: 0.0.0.0
              PORT: 3002
            ports:
              - "${cfg.listenAddress}:${toString cfg.port}:3002"
            command: node dist/src/index.js
            healthcheck:
              test:
                - CMD
                - curl
                - --fail
                - --silent
                - http://127.0.0.1:3002/
              interval: 15s
              timeout: 5s
              retries: 12
              start_period: 20s

          queue-worker:
            <<: *firecrawl-service
            environment:
              <<: *common-env
              WORKER_PORT: 3005
              NUQ_POD_NAME: queue-worker
            command: node dist/src/services/queue-worker.js

          nuq-worker:
            <<: *firecrawl-service
            environment:
              <<: *common-env
              NUQ_WORKER_PORT: 3006
              NUQ_POD_NAME: nuq-worker-0
            command: node dist/src/services/worker/nuq-worker.js

          nuq-reconciler:
            <<: *firecrawl-service
            environment:
              <<: *common-env
              NUQ_RECONCILER_WORKER_PORT: 3012
              NUQ_POD_NAME: nuq-reconciler-0
            command: node dist/src/services/worker/nuq-reconciler-worker.js

          redis:
            image: ${redisImage}
            networks:
              - backend
            command: redis-server --save "" --appendonly no
            healthcheck:
              test:
                - CMD
                - redis-cli
                - ping
              interval: 5s
              timeout: 3s
              retries: 12
            restart: unless-stopped
            logging: *default-logging

          nuq-postgres:
            image: ${postgresImage}
            environment:
              POSTGRES_USER: postgres
              POSTGRES_PASSWORD: postgres
              POSTGRES_DB: postgres
            networks:
              - backend
            volumes:
              - nuq-postgres-data:/var/lib/postgresql/data
            healthcheck:
              test:
                - CMD-SHELL
                - pg_isready -U postgres -d postgres
              interval: 5s
              timeout: 3s
              retries: 24
              start_period: 10s
            restart: unless-stopped
            logging: *default-logging

        networks:
          backend:

        volumes:
          nuq-postgres-data:
  '';
in
{
  #============================================================================
  # OPTIONS
  #============================================================================
  options.modules.services.firecrawl = {
    enable = mkEnableOption "self-hosted Firecrawl search and extraction service";

    listenAddress = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Address on which the Firecrawl API is exposed.";
    };

    port = mkOption {
      type = types.port;
      default = 38473;
      description = "Port on which the Firecrawl API is exposed.";
    };

    llm = {
      enable = mkEnableOption "Codex-subscription-backed Firecrawl JSON and summary extraction";

      model = mkOption {
        type = types.str;
        default = "gpt-5.4-mini";
        description = "Codex model exposed through the internal OpenAI-compatible proxy.";
      };
    };

    camofox.enable = mkEnableOption "Camoufox anti-detection browser backend with Playwright retained for rollback";
  };

  #============================================================================
  # CONFIG
  #============================================================================
  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = !cfg.camofox.enable || pkgs.stdenv.hostPlatform.isx86_64;
        message = "The pinned Firecrawl Camoufox browser bundle currently supports only x86_64-linux.";
      }
    ];

    virtualisation.oci-containers.backend = mkDefault "docker";

    environment.systemPackages = [ pkgs.docker-compose ];

    systemd.tmpfiles.rules = [
      "d /var/lib/firecrawl 0750 root root -"
      "d /var/lib/firecrawl/codex-auth 0700 root root -"
    ];

    systemd.services.firecrawl = {
      description = "Self-hosted Firecrawl stack";
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
        Type = "exec";
        WorkingDirectory = "/var/lib/firecrawl";
        ExecStart = "${pkgs.docker-compose}/bin/docker-compose -f ${composeFile} up --remove-orphans";
        ExecStop = "${pkgs.docker-compose}/bin/docker-compose -f ${composeFile} down";
        Restart = "on-failure";
        RestartSec = "10s";
        TimeoutStartSec = "15min";
        TimeoutStopSec = "2min";
      };
    };
  };
}
