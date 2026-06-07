{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.modules.services.opencode-server;
  opencodePkg = cfg.package;
in
{
  #============================================================================
  # OPTIONS
  #============================================================================
  options.modules.services.opencode-server = {
    enable = mkEnableOption "OpenCode headless HTTP server (opencode serve)";

    package = mkOption {
      type = types.package;
      default = pkgs.opencode;
      defaultText = literalExpression "pkgs.opencode";
      description = "OpenCode package to use for the server";
    };

    host = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Hostname/IP to bind the server to (e.g., NetBird IP for mesh access)";
    };

    port = mkOption {
      type = types.port;
      default = 4096;
      description = "Port to listen on";
    };

    user = mkOption {
      type = types.str;
      default = "fractal-tess";
      description = "User to run the server as (uses their config and workspace)";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Open firewall port for the server";
    };

    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Additional CLI flags passed to opencode serve (e.g., --print-logs)";
    };
  };

  #============================================================================
  # CONFIG
  #============================================================================
  config = mkIf cfg.enable {
    # Ensure opencode is available in system path
    environment.systemPackages = [ opencodePkg ];

    # Open firewall port if requested
    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];

    # Systemd service for the headless server
    systemd.services.opencode-server = {
      description = "OpenCode Remote Server";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.user;
        Restart = "on-failure";
        RestartSec = "5";

        # Need home directory access for ~/.config/opencode and ~/.local/share/opencode
        WorkingDirectory = "/home/${cfg.user}";
        StateDirectory = "opencode";
        ProtectSystem = "off";
        ProtectHome = "no";
        PrivateTmp = false;
        NoNewPrivileges = false;
      };

      script = ''
        export HOME=/home/${cfg.user}
        exec ${opencodePkg}/bin/opencode serve \
          --hostname ${cfg.host} \
          --port ${toString cfg.port} \
          ${lib.escapeShellArgs cfg.extraArgs}
      '';
    };
  };
}
