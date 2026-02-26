{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.modules.services.kimi-web;
  # Wrapper script for kimi-cli
  kimi-cli = pkgs.writeShellScriptBin "kimi-cli" ''
    exec ${pkgs.uv}/bin/uv tool run --python 3.13 kimi-cli "$@"
  '';
in
{
  options.modules.services.kimi-web = {
    enable = mkEnableOption "Kimi CLI Web UI server";

    port = mkOption {
      type = types.port;
      default = 5494;
      description = "Port to bind the Web UI server to";
    };

    host = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "Host address to bind to (0.0.0.0 for all interfaces)";
    };

    allowedOrigins = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "List of allowed origin URLs (e.g., http://neo.netbird.cloud:5494)";
    };

    workDir = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Default working directory for sessions";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = true;
      description = "Open firewall port for the Web UI";
    };

    user = mkOption {
      type = types.str;
      default = "fractal-tess";
      description = "User to run the service as";
    };
  };

  config = mkIf cfg.enable {
    # Open firewall port
    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];

    # Create systemd user service
    systemd.services.kimi-web = {
      description = "Kimi CLI Web UI Server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.user;
        WorkingDirectory = cfg.workDir or "/home/${cfg.user}";
        Restart = "on-failure";
        RestartSec = 5;

        # Security hardening (still appropriate even with --dangerously-omit-auth)
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = "read-only";
        ReadWritePaths = [ "/home/${cfg.user}" ];
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
        PrivateTmp = true;
      };

      script = let
        allowedOriginsStr = if cfg.allowedOrigins != [ ]
          then "--allowed-origins=${lib.concatStringsSep "," cfg.allowedOrigins}"
          else "";
        workDirStr = if cfg.workDir != null
          then "--work-dir=${cfg.workDir}"
          else "";
      in ''
        export HOME=/home/${cfg.user}
        export PATH="${pkgs.uv}/bin:$PATH"

        exec ${kimi-cli}/bin/kimi-cli --yolo web \
          --host ${cfg.host} \
          --port ${toString cfg.port} \
          --public \
          --network \
          --dangerously-omit-auth \
          --no-open \
          ${allowedOriginsStr} \
          ${workDirStr}
      '';
    };

    # Ensure uv is available system-wide
    environment.systemPackages = [ pkgs.uv ];
  };
}
