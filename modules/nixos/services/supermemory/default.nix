{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.modules.services.supermemory;
  cliproxyapi = config.modules.services.cliproxyapi;
  llama-server = getExe' pkgs.llama-cpp-cuda "llama-server";
  routerUrl = "http://127.0.0.1:${toString cfg.routerPort}/v1";
  swapUrl = "http://127.0.0.1:${toString cfg.modelPort}";
in
{
  #============================================================================
  # IMPORTS
  #============================================================================
  imports = [ inputs.supermemory-flake.nixosModules.default ];

  #============================================================================
  # OPTIONS
  #============================================================================
  options.modules.services.supermemory = {
    enable = mkEnableOption "the self-hosted Supermemory server, the shared memory store for coding agents";

    port = mkOption {
      type = types.port;
      default = 6767;
      description = "Port for the HTTP API";
    };

    model = mkOption {
      type = types.str;
      default = "gpt-6-luna";
      description = "CLIProxyAPI model that chunks text and extracts memories. Must support tool calling";
    };

    fallbackModel = mkOption {
      type = types.str;
      default = "/var/lib/supermemory-models/Ornith-1.5-9B-Q4_K_M.gguf";
      description = "Local GGUF used when CLIProxyAPI fails. Loaded on demand and unloaded when idle, so keep it on the NVMe for fast cold starts (copied from /mnt/vault by hand)";
    };

    embeddingModel = mkOption {
      type = types.str;
      default = "/var/lib/supermemory-models/ggml-org-bge-m3-q8_0.gguf";
      description = ''
        Local bge-m3 GGUF for embeddings. The stored vectors are bge-m3, so a
        different model needs a fresh data directory
      '';
    };

    gpu = mkOption {
      type = types.str;
      default = "0";
      description = "CUDA device the local models run on (GPU 1 runs hot until its riser cable is replaced)";
    };

    routerPort = mkOption {
      type = types.port;
      default = 11639;
      description = "Local port of the router that falls back from CLIProxyAPI to the local model";
    };

    modelPort = mkOption {
      type = types.port;
      default = 11640;
      description = "Local port of llama-swap, which serves the embedding and fallback models";
    };

    firewallInterfaces = mkOption {
      type = types.listOf types.str;
      default = [ "wt0" ];
      description = "Interfaces to open the port on. Defaults to the NetBird mesh only";
    };
  };

  #============================================================================
  # CONFIG
  #============================================================================
  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cliproxyapi.enable && cliproxyapi.requireApiKey;
        message = "Supermemory extracts memories through CLIProxyAPI; enable modules.services.cliproxyapi.";
      }
    ];

    services.supermemory-server = {
      enable = true;
      inherit (cfg) port firewallInterfaces;
      # The plugin's search and save tools need MCP, which the server lacks.
      mcp.enable = true;
      llm = {
        baseUrl = routerUrl;
        inherit (cfg) model;
      };
      # Must match embedding-plan.json in the data directory, or the server
      # refuses to start.
      embeddings = {
        provider = "openai-compatible";
        baseUrl = "${swapUrl}/v1";
        model = "bge-m3";
        dimensions = 1024;
      };
      # The router holds the real key; the server only insists one is set.
      environment.OPENAI_API_KEY = "local";
    };

    # Embeddings stay loaded (0.6 GB). The fallback LLM (about 6.5 GB) loads
    # only when CLIProxyAPI fails and unloads after 15 idle minutes.
    services.llama-swap = {
      enable = true;
      port = cfg.modelPort;
      settings = {
        healthCheckTimeout = 300;
        models = {
          bge-m3 = {
            cmd = "${llama-server} --port \${PORT} -m ${cfg.embeddingModel} --embedding --pooling cls -c 8192 -ngl 999 -fit off --no-ui";
            env = [ "CUDA_VISIBLE_DEVICES=${cfg.gpu}" ];
          };
          fallback = {
            cmd = "${llama-server} --port \${PORT} -m ${cfg.fallbackModel} --jinja -c 32768 -ngl 999 -fit off --flash-attn on --parallel 1 --cache-ram 0 --no-ui";
            env = [ "CUDA_VISIBLE_DEVICES=${cfg.gpu}" ];
            ttl = 900;
          };
        };
        groups.supermemory = {
          swap = false;
          members = [
            "bge-m3"
            "fallback"
          ];
        };
        hooks.on_startup.preload = [ "bge-m3" ];
      };
    };

    systemd.services.llama-swap = {
      unitConfig.RequiresMountsFor = [
        cfg.embeddingModel
        cfg.fallbackModel
      ];
      # CUDA JIT-compiles kernels into writable, executable memory.
      serviceConfig.MemoryDenyWriteExecute = mkForce false;
    };

    systemd.services.supermemory-llm-router = {
      description = "Supermemory LLM router: CLIProxyAPI with a local fallback";
      wantedBy = [ "multi-user.target" ];
      after = [
        "sops-nix.service"
        "cliproxyapi.service"
        "llama-swap.service"
      ];
      environment = {
        ROUTER_PORT = toString cfg.routerPort;
        PRIMARY_URL = "http://${cliproxyapi.listenAddress}:${toString cliproxyapi.proxyPort}";
        PRIMARY_MODEL = cfg.model;
        FALLBACK_URL = swapUrl;
        FALLBACK_MODEL = "fallback";
      };
      serviceConfig = {
        ExecStart = "${pkgs.python3}/bin/python3 -u ${./router.py}";
        LoadCredential = "primary-key:${config.sops.secrets.cliproxyapi_client_api_key.path}";
        DynamicUser = true;
        Restart = "always";
        RestartSec = 3;
      };
    };

    systemd.services.supermemory-server = {
      after = [
        "supermemory-llm-router.service"
        "llama-swap.service"
      ];
      wants = [
        "supermemory-llm-router.service"
        "llama-swap.service"
      ];
      # It idles near 1.5 GB. Cap it so a runaway (it once reached 20 GB when
      # embeddings fell back to WebAssembly) restarts it instead of starving
      # the rest of the machine.
      serviceConfig.MemoryMax = "6G";
    };
  };
}
