{
  config,
  inputs,
  lib,
  ...
}:

with lib;

let
  cfg = config.modules.services.supermemory;
  proxy = config.modules.services.cliproxyapi;
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
      default = "gpt-5.5";
      description = "Model on the local CLIProxyAPI used for memory extraction";
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
        assertion = proxy.enable && proxy.requireApiKey;
        message = "Supermemory uses this host's CLIProxyAPI for memory extraction; enable modules.services.cliproxyapi.";
      }
    ];

    services.supermemory-server = {
      enable = true;
      inherit (cfg) port firewallInterfaces;
      # Memory extraction goes through the CLIProxyAPI already running here,
      # so no separate provider key is needed.
      environment = {
        OPENAI_BASE_URL = "http://${proxy.listenAddress}:${toString proxy.proxyPort}/v1";
        OPENAI_MODEL = cfg.model;
      };
      environmentFile = config.sops.templates."supermemory.env".path;
    };

    sops.templates."supermemory.env" = {
      content = "OPENAI_API_KEY=${config.sops.placeholder.cliproxyapi_client_api_key}";
      owner = config.services.supermemory-server.user;
      mode = "0400";
    };

    systemd.services.supermemory-server = {
      after = [ "cliproxyapi.service" ];
      wants = [ "cliproxyapi.service" ];
      # It idles near 1.5 GB. Cap it so a runaway (it once reached 20 GB when
      # embeddings fell back to WebAssembly) restarts it instead of starving
      # the rest of the machine.
      serviceConfig.MemoryMax = "6G";
    };
  };
}
