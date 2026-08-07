{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.modules.services.firecrawl;
  browserConcurrency = if cfg.agent.enable then cfg.agent.maxConcurrentJobs else 2;

  # Pinned multi-architecture image indexes from 2026-07-27.
  firecrawlImage = "ghcr.io/firecrawl/firecrawl@sha256:d2fe554a1a723d95f3af3ceb4146db5765efaba7fb1b1850f8fd2713b11da7f6";
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
  cliProxyDashboardImage = "ghcr.io/itsmylife44/cliproxyapi-dashboard/dashboard@sha256:8d6ac25c48cbc7510ceecda07238e64efa1f42c383df25ea5f7878f0d951a762";
  cliProxyPostgresImage = "postgres@sha256:57c72fd2a128e416c7fcc499958864df5301e940bca0a56f58fddf30ffc07777";
  nodeImage = "node@sha256:6c74791e557ce11fc957704f6d4fe134a7bc8d6f5ca4403205b2966bd488f6b3";
  searxngImage = "searxng/searxng@sha256:5d6d903ab82afa56ee32792d477f36bc63d3e5ca04fcb6947e28a5cfd987fad3";
  agentInteropSecret = "firecrawl-local-agent-v1";
  camofoxInteractSecret = "firecrawl-local-interact-v1";
  cliProxyDashboardEnvFile = "/var/lib/firecrawl/cliproxy-dashboard.env";
  codexProxyConfigFile = "/var/lib/firecrawl/codex-config.yaml";

  codexProxyConfig = pkgs.writeText "firecrawl-codex-proxy.yaml" ''
    host: 0.0.0.0
    port: 8317
    auth-dir: /root/.cli-proxy-api
    api-keys:
      - local-firecrawl
    usage-statistics-enabled: true
    remote-management:
      allow-remote: ${boolToString cfg.dashboard.enable}
      secret-key: ""
      disable-control-panel: true
  '';
  firecrawlRuntimePatch = ./firecrawl-runtime-patch.mjs;
  firecrawlRuntimePatches = pkgs.runCommand "firecrawl-runtime-patches" { } ''
    mkdir -p "$out"
    cp ${./runtime-patches/agent-cancel.js} "$out/agent-cancel.js"
    cp ${./runtime-patches/agent-status.js} "$out/agent-status.js"
    cp ${./runtime-patches/image-analyze.js} "$out/image-analyze.js"
    cp ${./runtime-patches/interact-local.js} "$out/interact-local.js"
    cp ${./runtime-patches/routes-v2.js} "$out/routes-v2.js"
    cp ${./runtime-patches/search-v2-index.js} "$out/search-v2-index.js"
    cp ${./runtime-patches/search-v2-searxng.js} "$out/search-v2-searxng.js"
  '';
  firecrawlAgent = import ./firecrawl-agent-package.nix {
    inherit pkgs;
    serverSource = ./firecrawl-agent-server.ts;
  };
  searxngSettings = pkgs.writeText "firecrawl-searxng-settings.yml" ''
    use_default_settings: true
    server:
      secret_key: "firecrawl-internal-searxng"
      bind_address: "0.0.0.0"
      port: 8080
      limiter: false
      image_proxy: false
    search:
      safe_search: 0
      autocomplete: ""
      default_lang: "en"
      formats:
        - html
        - json
    outgoing:
      request_timeout: 10.0
      max_request_timeout: 15.0
    engines:
      - name: lucide
        disabled: true
      - name: devicons
        disabled: true
  '';
  pdfOcrImage = import ./pdf-ocr-image.nix {
    inherit pkgs;
    serverSource = ./pdf-ocr-server.py;
  };
  firecrawlPatchedEntrypoint = pkgs.writeText "firecrawl-patched-entrypoint.sh" ''
    #!/bin/sh
    set -eu
    node /opt/firecrawl/runtime-patch.mjs
    exec docker-entrypoint.sh "$@"
  '';

  indentYaml =
    indentation: text:
    concatStringsSep "\n" (map (line: "${indentation}${line}") (splitString "\n" text));

  nuqWorkerServices = concatMapStringsSep "\n" (index: ''
    nuq-worker-${toString index}:
      <<: *firecrawl-service
      cpus: "1.0"
      mem_limit: 1280m
      pids_limit: 192
      environment:
        <<: *common-env
        NUQ_WORKER_PORT: 3006
        NUQ_POD_NAME: nuq-worker-${toString index}
      command: node dist/src/services/worker/nuq-worker.js
      healthcheck:
        test:
          - CMD
          - curl
          - --fail
          - --silent
          - http://127.0.0.1:3006/health
        interval: 15s
        timeout: 5s
        retries: 12
        start_period: 20s
  '') (range 0 (browserConcurrency - 1));

  camofoxService = ''
    # Private Firecrawl-compatible Camoufox browser backend.
    camofox-scrape:
      image: ${camofoxImage}
      init: true
      user: "1000:1000"
      read_only: true
      cap_drop:
        - ALL
      security_opt:
        - no-new-privileges:true
      cpus: "${toString browserConcurrency}.0"
      mem_limit: ${toString (browserConcurrency + 1)}g
      pids_limit: ${toString (128 + browserConcurrency * 96)}
      ulimits:
        nofile:
          soft: 4096
          hard: 4096
      command:
        - /bin/sh
        - -c
        - mkdir -p /tmp/home/.cache && ln -s /opt/camoufox /tmp/home/.cache/camoufox && exec node /app/firecrawl-scrape.mjs
      environment:
        PORT: "3000"
        MAX_CONCURRENT_PAGES: "${toString browserConcurrency}"
        MAX_QUEUED_PAGES: "${toString (browserConcurrency * 2)}"
        MAX_SCREENSHOT_BYTES: "8388608"
        MAX_SCREENSHOT_PIXELS: "40000000"
        MAX_ACTION_OUTPUT_BYTES: "25165824"
        MAX_JAVASCRIPT_RESULT_BYTES: "1048576"
        CAMOFOX_INTERACT_SECRET: ${camofoxInteractSecret}
        MAX_CONCURRENT_SESSIONS: "2"
        SESSION_IDLE_MS: "120000"
        SESSION_MAX_MS: "600000"
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

  searxngService = ''
    searxng:
      image: ${searxngImage}
      networks:
        - backend
      volumes:
        - ${searxngSettings}:/etc/searxng/settings.yml:ro
      cpus: "1.0"
      mem_limit: 1g
      pids_limit: 128
      tmpfs:
        - /tmp:rw,nosuid,nodev,mode=1777,size=256m
      healthcheck:
        test:
          - CMD
          - wget
          - --quiet
          - --spider
          - http://127.0.0.1:8080/healthz
        interval: 15s
        timeout: 5s
        retries: 12
        start_period: 30s
      restart: unless-stopped
      logging: *default-logging
  '';

  agentService = ''
    agent:
      image: ${nodeImage}
      init: true
      user: "1000:1000"
      read_only: true
      cap_drop:
        - ALL
      security_opt:
        - no-new-privileges:true
      cpus: "${toString (if cfg.agent.maxConcurrentJobs < 2 then 2 else cfg.agent.maxConcurrentJobs)}.0"
      mem_limit: ${toString (2 + cfg.agent.maxConcurrentJobs)}g
      pids_limit: ${toString (128 + cfg.agent.maxConcurrentJobs * 128)}
      command:
        - node
        - /app/server.mjs
      environment:
        PORT: "3000"
        AGENT_INTEROP_SECRET: ${agentInteropSecret}
        AGENT_JOB_DIR: /data/jobs
        FIRECRAWL_API_URL: http://api:3002
        FIRECRAWL_API_KEY: fc-local-firecrawl
        OPENAI_BASE_URL: http://codex-proxy:8317/v1
        OPENAI_API_KEY: local-firecrawl
        MODEL_NAME: ${cfg.llm.model}
        PRO_MODEL_NAME: ${cfg.llm.proModel}
        MAX_CONCURRENT_AGENT_JOBS: "${toString cfg.agent.maxConcurrentJobs}"
        MAX_QUEUED_AGENT_JOBS: "${toString cfg.agent.maxQueuedJobs}"
        MAX_AGENT_STEPS: "24"
        AGENT_TIMEOUT_MS: "300000"
        MAX_IMAGE_BYTES: "8388608"
        MAX_IMAGES_PER_REQUEST: "4"
        IMAGE_ANALYSIS_TIMEOUT_MS: "120000"
        MAX_AGENT_EVENTS: "128"
        NODE_OPTIONS: --max-old-space-size=1024
      volumes:
        - ${firecrawlAgent}/app:/app:ro
        - /var/lib/firecrawl/agent:/data
      networks:
        - backend
      depends_on:
        api:
          condition: service_healthy
        codex-proxy:
          condition: service_started
      healthcheck:
        test:
          - CMD
          - node
          - -e
          - fetch('http://127.0.0.1:3000/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))
        interval: 15s
        timeout: 5s
        retries: 12
        start_period: 30s
      tmpfs:
        - /tmp:rw,nosuid,nodev,mode=1777,size=512m
      restart: unless-stopped
      logging: *default-logging
  '';

  cliProxyDashboardServices = optionalString cfg.dashboard.enable ''
    cliproxy-postgres:
      image: ${cliProxyPostgresImage}
      cpus: "0.5"
      mem_limit: 256m
      mem_reservation: 64m
      networks:
        - backend
      environment:
        POSTGRES_DB: cliproxyapi
        POSTGRES_USER: cliproxyapi
        POSTGRES_PASSWORD: "''${POSTGRES_PASSWORD}"
        TZ: UTC
      volumes:
        - cliproxy-postgres-data:/var/lib/postgresql/data
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

    cliproxy-dashboard:
      image: ${cliProxyDashboardImage}
      cpus: "1.0"
      mem_limit: 512m
      mem_reservation: 128m
      networks:
        - backend
      ports:
        - "${cfg.dashboard.listenAddress}:${toString cfg.dashboard.port}:3000"
      environment:
        DATABASE_URL: "postgresql://cliproxyapi:''${POSTGRES_PASSWORD}@cliproxy-postgres:5432/cliproxyapi"
        CLIPROXYAPI_MANAGEMENT_URL: http://codex-proxy:8317/v0/management
        MANAGEMENT_API_KEY: "''${MANAGEMENT_API_KEY}"
        JWT_SECRET: "''${JWT_SECRET}"
        NODE_ENV: production
        API_URL: "http://${cfg.dashboard.listenAddress}:${toString cfg.dashboard.proxyPort}"
        DASHBOARD_URL: "http://${cfg.dashboard.listenAddress}:${toString cfg.dashboard.port}"
        CLIPROXYAPI_CONTAINER_NAME: firecrawl-codex-proxy-1
        ALLOW_LOCAL_PROVIDER_URLS: "true"
      volumes:
        - cliproxy-dashboard-backups:/app/backups
      depends_on:
        cliproxy-postgres:
          condition: service_healthy
        codex-proxy:
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
  '';

  pdfOcrService = ''
    pdf-ocr:
      image: firecrawl-pdf-ocr:local
      init: true
      user: "65532:65532"
      read_only: true
      cap_drop:
        - ALL
      security_opt:
        - no-new-privileges:true
      cpus: "2.0"
      mem_limit: 2g
      pids_limit: 128
      environment:
        PORT: "8080"
        MAX_CONCURRENT: "2"
        MAX_QUEUED: "4"
        MAX_PAGES: "50"
        MAX_PDF_BYTES: "31457280"
        DEFAULT_DEADLINE_SECONDS: "300"
        OCR_DPI: "250"
        OCR_LANGUAGE: eng
      networks:
        - pdf-backend
      healthcheck:
        test:
          - CMD
          - ${pkgs.python3}/bin/python3
          - -c
          - "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8080/health', timeout=3)"
        interval: 15s
        timeout: 5s
        retries: 12
        start_period: 20s
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
          PLAYWRIGHT_MICROSERVICE_URL: http://camofox-scrape:3000/scrape
          CAMOFOX_INTERACT_URL: http://camofox-scrape:3000
          CAMOFOX_INTERACT_SECRET: ${camofoxInteractSecret}
          NUQ_DATABASE_URL: postgresql://postgres:postgres@nuq-postgres:5432/postgres
          NUQ_DATABASE_URL_LISTEN: postgresql://postgres:postgres@nuq-postgres:5432/postgres
          NUQ_WAIT_MODE: listen
          USE_DB_AUTHENTICATION: "false"
          ENV: local
          LOGGING_LEVEL: info
    ${optionalString cfg.search.imageSearch.enable "      SEARXNG_ENDPOINT: http://searxng:8080\n      SEARXNG_WEB_ENGINES: bing"}
    ${optionalString cfg.agent.enable "      EXTRACT_V3_BETA_URL: http://agent:3000\n      AGENT_INTEROP_SECRET: ${agentInteropSecret}"}
    ${optionalString cfg.pdfOcr.enable "      PDF_RUST_EXTRACT_ENABLE: \"true\"\n      FIRE_PDF_ENABLE: \"true\"\n      FIRE_PDF_PERCENT: \"100\"\n      FIRE_PDF_BASE_URL: http://pdf-ocr:8080"}
    ${optionalString cfg.llm.enable "      OPENAI_BASE_URL: http://codex-proxy:8317/v1\n      OPENAI_API_KEY: local-firecrawl\n      MODEL_NAME: ${cfg.llm.model}"}

        x-default-logging: &default-logging
          driver: json-file
          options:
            max-size: 10m
            max-file: "3"
            compress: "true"

        x-firecrawl-service: &firecrawl-service
          image: ${firecrawlImage}
          cpus: "2.0"
          mem_limit: 3g
          pids_limit: 256
          networks:
            - backend
    ${optionalString cfg.pdfOcr.enable "        - pdf-backend"}
          environment:
            <<: *common-env
          entrypoint:
            - /bin/sh
            - /opt/firecrawl/patched-entrypoint.sh
          volumes:
            - ${firecrawlRuntimePatch}:/opt/firecrawl/runtime-patch.mjs:ro
            - ${firecrawlRuntimePatches}:/opt/firecrawl/runtime-patches:ro
            - ${firecrawlPatchedEntrypoint}:/opt/firecrawl/patched-entrypoint.sh:ro
          depends_on:
            redis:
              condition: service_healthy
            nuq-postgres:
              condition: service_healthy
            camofox-scrape:
              condition: service_healthy
    ${optionalString cfg.llm.enable "        codex-proxy:\n          condition: service_started"}
    ${optionalString cfg.search.imageSearch.enable "        searxng:\n          condition: service_healthy"}
    ${optionalString cfg.pdfOcr.enable "        pdf-ocr:\n          condition: service_healthy"}
          restart: unless-stopped
          logging: *default-logging

        services:
    ${optionalString cfg.llm.enable "      codex-proxy:\n        image: ${codexProxyImage}\n        networks:\n          - backend\n        environment:\n          MANAGEMENT_PASSWORD: \"\${MANAGEMENT_API_KEY:-}\"\n        ports:\n${optionalString cfg.dashboard.enable "          - \"${cfg.dashboard.listenAddress}:${toString cfg.dashboard.proxyPort}:8317\"\n          - \"${cfg.dashboard.listenAddress}:8085:8085\"\n          - \"${cfg.dashboard.listenAddress}:1455:1455\"\n          - \"${cfg.dashboard.listenAddress}:54545:54545\"\n          - \"${cfg.dashboard.listenAddress}:51121:51121\"\n          - \"${cfg.dashboard.listenAddress}:11451:11451\""}\n        volumes:\n          - ${codexProxyConfigFile}:/CLIProxyAPI/config.yaml\n          - /var/lib/firecrawl/codex-auth:/root/.cli-proxy-api\n        restart: unless-stopped\n        logging: *default-logging"}

    ${indentYaml "      " cliProxyDashboardServices}
    ${optionalString cfg.search.imageSearch.enable (indentYaml "      " searxngService)}
    ${optionalString cfg.pdfOcr.enable (indentYaml "      " pdfOcrService)}
    ${optionalString cfg.agent.enable (indentYaml "      " agentService)}
    ${indentYaml "      " camofoxService}

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
                - http://127.0.0.1:3002/v0/health/liveness
              interval: 15s
              timeout: 5s
              retries: 12
              start_period: 20s

          queue-worker:
            <<: *firecrawl-service
            cpus: "1.0"
            mem_limit: 1g
            pids_limit: 192
            environment:
              <<: *common-env
              WORKER_PORT: 3005
              NUQ_POD_NAME: queue-worker
            command: node dist/src/services/queue-worker.js
            healthcheck:
              test:
                - CMD
                - curl
                - --fail
                - --silent
                - http://127.0.0.1:3005/liveness
              interval: 15s
              timeout: 5s
              retries: 12
              start_period: 20s

    ${indentYaml "      " nuqWorkerServices}

          nuq-reconciler:
            <<: *firecrawl-service
            cpus: "0.25"
            mem_limit: 256m
            pids_limit: 96
            environment:
              <<: *common-env
              NUQ_RECONCILER_WORKER_PORT: 3012
              NUQ_POD_NAME: nuq-reconciler-0
            command: node dist/src/services/worker/nuq-reconciler-worker.js
            healthcheck:
              test:
                - CMD
                - curl
                - --fail
                - --silent
                - http://127.0.0.1:3012/health
              interval: 15s
              timeout: 5s
              retries: 12
              start_period: 20s

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
    ${optionalString cfg.pdfOcr.enable "      pdf-backend:\n        internal: true"}

        volumes:
          nuq-postgres-data:
    ${optionalString cfg.dashboard.enable "      cliproxy-postgres-data:\n      cliproxy-dashboard-backups:"}
  '';
  firecrawlStart = pkgs.writeShellScript "firecrawl-start" ''
    set -euo pipefail
    if [[ ! -s ${codexProxyConfigFile} ]]; then
      ${pkgs.coreutils}/bin/install -m 0600 ${codexProxyConfig} ${codexProxyConfigFile}
    fi
    ${optionalString cfg.dashboard.enable ''
      if [[ ! -s ${cliProxyDashboardEnvFile} ]]; then
        umask 077
        env_file="$(${pkgs.coreutils}/bin/mktemp ${cliProxyDashboardEnvFile}.XXXXXX)"
        postgres_password="$(${pkgs.openssl}/bin/openssl rand -hex 32)"
        management_api_key="$(${pkgs.openssl}/bin/openssl rand -hex 32)"
        jwt_secret="$(${pkgs.openssl}/bin/openssl rand -hex 32)"
        ${pkgs.coreutils}/bin/printf 'POSTGRES_PASSWORD=%s\nMANAGEMENT_API_KEY=%s\nJWT_SECRET=%s\n' \
          "$postgres_password" "$management_api_key" "$jwt_secret" > "$env_file"
        ${pkgs.coreutils}/bin/install -m 0600 "$env_file" ${cliProxyDashboardEnvFile}
        ${pkgs.coreutils}/bin/rm -f "$env_file"
      fi
    ''}
    ${pkgs.docker-compose}/bin/docker-compose -f ${composeFile} ${optionalString cfg.dashboard.enable "--env-file ${cliProxyDashboardEnvFile}"} up --detach --remove-orphans --wait --wait-timeout 600
    ${pkgs.systemd}/bin/systemd-notify --ready
    services="$(${pkgs.docker-compose}/bin/docker-compose -f ${composeFile} ${optionalString cfg.dashboard.enable "--env-file ${cliProxyDashboardEnvFile}"} config --services)"
    exec ${pkgs.docker-compose}/bin/docker-compose -f ${composeFile} ${optionalString cfg.dashboard.enable "--env-file ${cliProxyDashboardEnvFile}"} wait $services
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
        description = "Codex model used by the spark-1-mini compatibility alias.";
      };

      proModel = mkOption {
        type = types.str;
        default = "gpt-5.6-sol";
        description = "Higher-accuracy Codex model used by the spark-1-pro compatibility alias.";
      };
    };

    agent = {
      enable = mkEnableOption "local autonomous Firecrawl web agent and image-understanding service";

      maxConcurrentJobs = mkOption {
        type = types.ints.between 1 4;
        default = 1;
        description = "Maximum number of autonomous agent jobs executing concurrently.";
      };

      maxQueuedJobs = mkOption {
        type = types.ints.between 1 64;
        default = 8;
        description = "Maximum number of autonomous agent jobs waiting for an execution slot.";
      };
    };

    search.imageSearch.enable = mkEnableOption "SearXNG-backed web, news, and image search";

    dashboard = {
      enable = mkEnableOption "CLIProxyAPI web management dashboard";

      listenAddress = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "Address on which the CLIProxyAPI dashboard and proxy are exposed.";
      };

      port = mkOption {
        type = types.port;
        default = 38300;
        description = "Port on which the CLIProxyAPI dashboard is exposed.";
      };

      proxyPort = mkOption {
        type = types.port;
        default = 38317;
        description = "Port on which the dashboard-managed CLIProxyAPI endpoint is exposed.";
      };
    };

    pdfOcr.enable = mkEnableOption "local Rust-first PDF extraction with Poppler and Tesseract OCR fallback";

  };

  #============================================================================
  # CONFIG
  #============================================================================
  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isx86_64;
        message = "The pinned Firecrawl Camoufox browser bundle currently supports only x86_64-linux.";
      }
      {
        assertion = !cfg.agent.enable || cfg.llm.enable;
        message = "The local Firecrawl agent requires modules.services.firecrawl.llm.enable.";
      }
      {
        assertion = !cfg.dashboard.enable || cfg.llm.enable;
        message = "The CLIProxyAPI dashboard requires modules.services.firecrawl.llm.enable.";
      }
    ];

    virtualisation.oci-containers.backend = mkDefault "docker";

    environment.systemPackages = [ pkgs.docker-compose ];

    system.build = {
      firecrawlAgent = firecrawlAgent;
      firecrawlCompose = composeFile;
      firecrawlPdfOcrImage = pdfOcrImage;
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/firecrawl 0750 root root -"
      "d /var/lib/firecrawl/codex-auth 0700 root root -"
      "d /var/lib/firecrawl/agent 0750 1000 1000 -"
      "d /var/lib/firecrawl/agent/jobs 0750 1000 1000 -"
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
        Type = "notify";
        NotifyAccess = "all";
        WorkingDirectory = "/var/lib/firecrawl";
        ExecStartPre = optional cfg.pdfOcr.enable "${config.virtualisation.docker.package}/bin/docker load --input ${pdfOcrImage}";
        ExecStart = firecrawlStart;
        ExecStop = "${pkgs.docker-compose}/bin/docker-compose -f ${composeFile} ${optionalString cfg.dashboard.enable "--env-file ${cliProxyDashboardEnvFile}"} down";
        Restart = "on-failure";
        RestartSec = "10s";
        TimeoutStartSec = "15min";
        TimeoutStopSec = "2min";
      };
    };
  };
}
