{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.modules.services.shadoword-api;
  listenEndpoint = "${cfg.listenAddress}:${toString cfg.port}";
in
{
  #============================================================================
  # OPTIONS
  #============================================================================

  options.modules.services.shadoword-api = {
    enable = mkEnableOption "CUDA-accelerated Shadoword transcription API";

    package = mkOption {
      type = types.package;
      default = inputs.shadoword.packages.${pkgs.system}.shadoword-api-cuda;
      description = "Shadoword API package to run.";
    };

    listenAddress = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Address on which the API listens.";
    };

    port = mkOption {
      type = types.port;
      default = 47813;
      description = "TCP port on which the API listens.";
    };

    netbirdInterface = mkOption {
      type = types.str;
      default = "wt0";
      description = "NetBird interface allowed through the firewall.";
    };

    tokenFile = mkOption {
      type = types.path;
      description = "Protected file containing the API bearer token.";
    };

    modelId = mkOption {
      type = types.str;
      default = "turbo";
      description = "Catalog model ensured on disk before startup; the active model remains API-managed.";
    };
  };

  #============================================================================
  # CONFIG
  #============================================================================

  config = mkIf cfg.enable {
    users.groups.shadoword = { };
    users.users.shadoword = {
      isSystemUser = true;
      group = "shadoword";
      extraGroups = [
        "render"
        "video"
      ];
    };

    networking.firewall.interfaces.${cfg.netbirdInterface}.allowedTCPPorts = [ cfg.port ];

    systemd.services.shadoword-api = {
      description = "CUDA-accelerated Shadoword transcription API";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network-online.target"
        "netbird.service"
      ];
      wants = [ "network-online.target" ];

      environment = {
        RUST_LOG = "info";
        XDG_CONFIG_HOME = "/var/lib/shadoword/config";
        XDG_DATA_HOME = "/var/lib/shadoword/data";
      };

      serviceConfig = {
        Type = "simple";
        User = "shadoword";
        Group = "shadoword";
        StateDirectory = "shadoword";
        StateDirectoryMode = "0700";
        ExecStart = concatStringsSep " " [
          "${cfg.package}/bin/shadoword-api"
          "--listen"
          (escapeShellArg listenEndpoint)
          "--download-model"
          (escapeShellArg cfg.modelId)
          "--download-dir"
          (escapeShellArg "/var/lib/shadoword/models")
          "--token-file"
          (escapeShellArg cfg.tokenFile)
        ];
        Restart = "on-failure";
        RestartSec = "5s";
        TimeoutStartSec = "30min";
        TimeoutStopSec = "30s";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        ReadWritePaths = [ "/var/lib/shadoword" ];
      };
    };
  };
}
