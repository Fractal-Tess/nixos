{
  config,
  inputs,
  lib,
  osConfig,
  pkgs,
  ...
}:

let
  cfg = config.services.open-design;
  hostName = osConfig.networking.hostName;
  mcpPort = 7458;
  netbirdAddress = "100.91.0.3";
  netbirdOrigin = "http://${hostName}.netbird.cloud:${toString cfg.webFrontend.port}";

  caddyfile = pkgs.writeText "open-design-web.Caddyfile" ''
    {
      auto_https off
      admin off
      persist_config off
    }

    :${toString cfg.webFrontend.port} {
      handle /api/* {
        reverse_proxy 127.0.0.1:${toString cfg.port} {
          flush_interval -1
          transport http {
            read_timeout 86400s
            write_timeout 86400s
          }
        }
      }
      handle /artifacts/* {
        reverse_proxy 127.0.0.1:${toString cfg.port}
      }
      handle /frames/* {
        reverse_proxy 127.0.0.1:${toString cfg.port}
      }
      handle {
        root * ${cfg.webFrontend.package}
        try_files {path} {path}/ /index.html
        file_server
        encode gzip
      }
    }
  '';

in
{
  imports = [
    inputs.open-design.homeManagerModules.default
  ];

  services.open-design = {
    enable = true;
    autoStart = true;
    webFrontend = {
      enable = true;
      host = "0.0.0.0";
      allowedOrigins = [ netbirdOrigin ];
    };
  };

  # Upstream renders 0.0.0.0 as a Caddy Host matcher, which returns an empty
  # response for real hostnames. Use a host-agnostic listener; the daemon still
  # enforces the explicit browser origin above for all API requests.
  systemd.user.services.open-design-web.Service.ExecStart =
    lib.mkForce "${lib.getExe pkgs.caddy} run --config ${caddyfile} --adapter caddyfile";

  # Expose Open Design's stdio-only MCP server as Streamable HTTP over NetBird.
  # Keep the daemon itself on loopback and bind the proxy only to Neo's VPN IP.
  systemd.user.services.open-design-mcp = {
    Unit = {
      Description = "Open Design Streamable HTTP MCP proxy";
      After = [
        "network-online.target"
        "open-design.service"
      ];
      Requires = [ "open-design.service" ];
      Wants = [ "network-online.target" ];
    };

    Service = {
      Environment = [ "OD_DATA_DIR=${cfg.dataDir}" ];
      ExecStart = "${lib.getExe pkgs.mcp-proxy} --host ${netbirdAddress} --port ${toString mcpPort} -- ${lib.getExe cfg.package} mcp --daemon-url http://127.0.0.1:${toString cfg.port}";
      Restart = "always";
      RestartSec = 3;
    };

    Install.WantedBy = [ "default.target" ];
  };
}
