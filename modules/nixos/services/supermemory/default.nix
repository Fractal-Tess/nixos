{
  config,
  inputs,
  lib,
  ...
}:

with lib;

let
  cfg = config.modules.services.supermemory;
  openrouter = "https://openrouter.ai/api/v1";
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
      default = "google/gemini-2.5-flash";
      description = "OpenRouter model that chunks text and extracts memories. Must support tool calling";
    };

    embeddingModel = mkOption {
      type = types.str;
      default = "baai/bge-m3";
      description = "OpenRouter embedding model. Changing it needs a fresh data directory";
    };

    embeddingDimensions = mkOption {
      type = types.int;
      default = 1024;
      description = "Vector size the embedding model produces";
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
        assertion = config.modules.services.sops.enable;
        message = "Supermemory reads its OpenRouter key from SOPS; enable modules.services.sops.";
      }
    ];

    services.supermemory-server = {
      enable = true;
      inherit (cfg) port firewallInterfaces;
      # The plugin's search and save tools need MCP, which the server lacks.
      mcp.enable = true;
      # Extraction and embeddings both go through OpenRouter, so memory keeps
      # working whatever this host's GPUs are busy with.
      llm = {
        baseUrl = openrouter;
        inherit (cfg) model;
      };
      embeddings = {
        provider = "openai-compatible";
        baseUrl = openrouter;
        model = cfg.embeddingModel;
        dimensions = cfg.embeddingDimensions;
      };
      environmentFile = config.sops.templates."supermemory.env".path;
    };

    sops.secrets.supermemory_openrouter_api_key = {
      sopsFile = ../../../../secrets/supermemory.json;
      format = "json";
      restartUnits = [ "supermemory-server.service" ];
    };

    sops.templates."supermemory.env" = {
      content = "OPENAI_API_KEY=${config.sops.placeholder.supermemory_openrouter_api_key}";
      owner = config.services.supermemory-server.user;
      mode = "0400";
    };

    # It idles near 1.5 GB. Cap it so a runaway (it once reached 20 GB when
    # embeddings fell back to WebAssembly) restarts it instead of starving
    # the rest of the machine.
    systemd.services.supermemory-server.serviceConfig.MemoryMax = "6G";
  };
}
