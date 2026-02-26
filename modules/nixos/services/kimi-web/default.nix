{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.modules.services.kimi-web;
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

    # Create systemd service using the properly packaged kimi-cli
    systemd.services.kimi-web = {
      description = "Kimi CLI Web UI Server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.user;
        WorkingDirectory = if cfg.workDir != null then cfg.workDir else "/home/${cfg.user}";
        Restart = "on-failure";
        RestartSec = 5;

        # Relaxed security for proper operation
        NoNewPrivileges = false;
        ProtectSystem = "off";
        ProtectHome = "no";
        PrivateTmp = false;
      };

      script = let
        allowedOriginsStr = if cfg.allowedOrigins != [ ]
          then "--allowed-origins=${lib.concatStringsSep "," cfg.allowedOrigins}"
          else "";
        workDirStr = if cfg.workDir != null
          then "--work-dir=${cfg.workDir}"
          else "";
        cmd = "${pkgs.kimi-cli}/bin/kimi-cli --yolo ${workDirStr} web --host ${cfg.host} --port ${toString cfg.port} --public --network --dangerously-omit-auth --no-open ${allowedOriginsStr}";
      in ''
        export HOME=/home/${cfg.user}

        # Use expect to handle the interactive confirmation
        ${pkgs.expect}/bin/expect -c '
          spawn ${cmd}
          expect "continue:"
          send "I UNDERSTAND THE RISKS\r"
          set wait_result [wait]
          exit [lindex $wait_result 3]
        '
      '';
    };

    # Ensure kimi-cli and ripgrep are available
    environment.systemPackages = [ pkgs.kimi-cli pkgs.ripgrep ];
  };
}
