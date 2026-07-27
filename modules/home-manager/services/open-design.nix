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
  webPort = 38471;
  mcpAddress = "127.0.0.1";
  mcpPort = webPort + 1;
  netbirdOrigin = "http://${hostName}.netbird.cloud:${toString cfg.webFrontend.port}";

  mcpProxySupervisor = pkgs.writeShellScript "open-design-mcp-supervisor" ''
    set -u

    proxyPid=""

    cleanup() {
      if [[ -n "$proxyPid" ]] && kill -0 "$proxyPid" 2>/dev/null; then
        kill "$proxyPid" 2>/dev/null || true
      fi
      wait "$proxyPid" 2>/dev/null || true
    }

    trap cleanup EXIT
    trap 'exit 0' INT TERM

    ${lib.getExe pkgs.mcp-proxy} --host ${mcpAddress} --port ${toString mcpPort} -- \
      ${lib.getExe cfg.package} mcp --daemon-url http://127.0.0.1:${toString cfg.port} &
    proxyPid=$!

    childStarted=false
    for _ in {1..50}; do
      if ! kill -0 "$proxyPid" 2>/dev/null; then
        wait "$proxyPid"
        exit $?
      fi
      if ${lib.getExe' pkgs.procps "pgrep"} -P "$proxyPid" >/dev/null; then
        childStarted=true
        break
      fi
      ${pkgs.coreutils}/bin/sleep 0.1
    done

    if [[ "$childStarted" != true ]]; then
      echo "Open Design MCP child did not start" >&2
      exit 1
    fi

    while kill -0 "$proxyPid" 2>/dev/null; do
      if ! ${lib.getExe' pkgs.procps "pgrep"} -P "$proxyPid" >/dev/null; then
        echo "Open Design MCP child exited; restarting proxy" >&2
        exit 1
      fi
      ${pkgs.coreutils}/bin/sleep 1
    done

    wait "$proxyPid"
  '';

  mcpProxyKeepalive = pkgs.writeShellScript "open-design-mcp-keepalive" ''
    set -u

    endpoint="http://${mcpAddress}:${toString mcpPort}/mcp"
    headers=$(${pkgs.coreutils}/bin/mktemp)
    response=$(${pkgs.coreutils}/bin/mktemp)
    session=""

    cleanup() {
      if [[ -n "$session" ]]; then
        ${lib.getExe pkgs.curl} --silent --max-time 5 --request DELETE \
          --header "Accept: application/json, text/event-stream" \
          --header "Mcp-Session-Id: $session" \
          "$endpoint" >/dev/null 2>&1 || true
      fi
      ${pkgs.coreutils}/bin/rm -f "$headers" "$response"
    }

    recover() {
      echo "Open Design MCP health check failed; restarting proxy" >&2
      trap - EXIT
      cleanup
      ${pkgs.systemd}/bin/systemctl --user restart open-design-mcp.service
      exit 0
    }

    trap cleanup EXIT

    ${lib.getExe pkgs.curl} --silent --show-error --fail-with-body \
      --connect-timeout 3 --max-time 10 \
      --retry 10 --retry-connrefused --retry-delay 1 \
      --dump-header "$headers" --output "$response" \
      --header "Accept: application/json, text/event-stream" \
      --header "Content-Type: application/json" \
      --data '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"open-design-mcp-keepalive","version":"1.0.0"}}}' \
      "$endpoint" || recover

    session=$(${pkgs.gawk}/bin/awk 'BEGIN { IGNORECASE=1 } /^mcp-session-id:/ { gsub("\\r", "", $2); print $2 }' "$headers")
    [[ -n "$session" ]] || recover

    ${lib.getExe pkgs.curl} --silent --show-error --fail-with-body \
      --connect-timeout 3 --max-time 10 \
      --header "Accept: application/json, text/event-stream" \
      --header "Content-Type: application/json" \
      --header "Mcp-Session-Id: $session" \
      --data '{"jsonrpc":"2.0","method":"notifications/initialized"}' \
      "$endpoint" >/dev/null || recover

    ${lib.getExe pkgs.curl} --silent --show-error --fail-with-body \
      --connect-timeout 3 --max-time 10 \
      --output "$response" \
      --header "Accept: application/json, text/event-stream" \
      --header "Content-Type: application/json" \
      --header "Mcp-Session-Id: $session" \
      --data '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}' \
      "$endpoint" || recover

    ${lib.getExe pkgs.jq} --exit-status '.result.tools | length > 0' "$response" >/dev/null || recover
  '';

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

  home.packages = [ pkgs.mcp-proxy ];

  services.open-design = {
    enable = true;
    autoStart = true;
    webFrontend = {
      enable = true;
      host = "0.0.0.0";
      port = webPort;
      allowedOrigins = [ netbirdOrigin ];
    };
  };

  # Upstream renders 0.0.0.0 as a Caddy Host matcher, which returns an empty
  # response for real hostnames. Use a host-agnostic listener; the daemon still
  # enforces the explicit browser origin above for all API requests.
  systemd.user.services.open-design-web.Service.ExecStart =
    lib.mkForce "${lib.getExe pkgs.caddy} run --config ${caddyfile} --adapter caddyfile";

  # Expose Open Design's stdio-only MCP server as Streamable HTTP to local
  # clients. Each workstation runs its own daemon so launched agents can access
  # that workstation's files.
  systemd.user.services.open-design-mcp = {
    Unit = {
      Description = "Open Design Streamable HTTP MCP proxy";
      After = [
        "network-online.target"
        "open-design.service"
      ];
      Requires = [ "open-design.service" ];
      PartOf = [ "open-design.service" ];
      Wants = [ "network-online.target" ];
      StartLimitIntervalSec = 0;
    };

    Service = {
      Environment = [ "OD_DATA_DIR=${cfg.dataDir}" ];
      # `od mcp` exits after 30 idle minutes. Supervise its child process so
      # mcp-proxy is restarted instead of remaining up with a dead backend.
      ExecStart = mcpProxySupervisor;
      Restart = "always";
      RestartSec = 3;
    };

    Install.WantedBy = [ "default.target" ];
  };

  # Keep the upstream stdio server active and verify that requests traverse the
  # HTTP proxy. The supervisor above provides recovery if either process exits.
  systemd.user.services.open-design-mcp-keepalive = {
    Unit = {
      Description = "Open Design MCP keepalive and health check";
      After = [ "open-design-mcp.service" ];
      Wants = [ "open-design-mcp.service" ];
    };

    Service = {
      Type = "oneshot";
      ExecStart = mcpProxyKeepalive;
    };
  };

  systemd.user.timers.open-design-mcp-keepalive = {
    Unit.Description = "Periodically keep Open Design MCP alive";
    Timer = {
      OnBootSec = "5min";
      OnUnitActiveSec = "20min";
      AccuracySec = "30s";
      Unit = "open-design-mcp-keepalive.service";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
