{
  config,
  inputs,
  lib,
  pkgs,
  username,
  ...
}:

with lib;

let
  cfg = config.modules.services.t3code-server;
  upstreamPackage = inputs.t3code-flake.packages.${pkgs.stdenv.hostPlatform.system}.t3code-server;

  # T3 Code calls `glab` at startup and on a timer, and waits on it without
  # killing it. When glab blocks (it does while the desktop keyring is locked)
  # the whole server stops answering, so bound every call from the service.
  glabGuard = pkgs.writeShellScriptBin "glab" ''
    case "$1 $2" in
      "auth status") limit=3 ;;
      *) limit=30 ;;
    esac
    exec ${pkgs.coreutils}/bin/timeout --signal=KILL "$limit" /run/current-system/sw/bin/glab "$@"
  '';
in
{
  #============================================================================
  # IMPORTS
  #============================================================================
  imports = [ inputs.t3code-flake.nixosModules.default ];

  #============================================================================
  # OPTIONS
  #============================================================================
  options.modules.services.t3code-server = {
    enable = mkEnableOption "the headless T3 Code server, started at boot so paired devices can always reach it";

    port = mkOption {
      type = types.port;
      default = 33773;
      description = "Port for the HTTP/WebSocket server. Kept off 3773, which the desktop app uses";
    };

    baseDir = mkOption {
      type = types.str;
      default = "%h/.t3-server";
      description = "Data directory. Kept apart from ~/.t3, which the desktop app uses";
    };

    firewallInterfaces = mkOption {
      type = types.listOf types.str;
      default = [ "wt0" ];
      description = "Interfaces to open the port on. Defaults to the NetBird mesh only";
    };

    remoteOpenHost = mkOption {
      type = types.nullOr types.str;
      default = "${config.networking.hostName}.netbird.cloud";
      description = ''
        SSH host that clients use for "open in editor" links (Zed, VS Code).
        Upstream only offers a Tailscale name and `<hostname>.local`, neither
        of which reaches this machine over NetBird. Null keeps upstream's list.
      '';
    };
  };

  #============================================================================
  # CONFIG
  #============================================================================
  config = mkIf cfg.enable {
    # The desktop app runs its own server on port 3773 with ~/.t3, so this one
    # gets its own port and data directory and the two can run side by side.
    services.t3code-server = {
      enable = true;
      user = username;
      host = "0.0.0.0";
      inherit (cfg) port baseDir firewallInterfaces;
      path = [
        "${glabGuard}/bin"
        "/run/wrappers/bin"
        "%h/.nix-profile/bin"
        "/etc/profiles/per-user/%u/bin"
        "/run/current-system/sw/bin"
      ];
      # Upstream hard-codes a 30-day lifetime for paired-device sessions and
      # never extends it, which forces a monthly re-pair. Every session needs
      # an expiry, so use 100 years as "never"; revoke devices by hand with
      # `t3 auth session revoke`. The server bundle is split into chunks
      # whose names carry a content hash, so find the one that defines the
      # constant; the build fails if none does.
      package = upstreamPackage.overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          ttlFiles=$(grep -rlF 'const DEFAULT_SESSION_TTL = days(30);' \
            "$out/lib/t3code/apps/server/dist" || true)
          if [ -z "$ttlFiles" ]; then
            echo "t3code-server: DEFAULT_SESSION_TTL not found; update the session TTL patch" >&2
            exit 1
          fi
          for file in $ttlFiles; do
            substituteInPlace "$file" \
              --replace-fail 'const DEFAULT_SESSION_TTL = days(30);' \
                             'const DEFAULT_SESSION_TTL = days(36500);'
          done

          # Advertise T3CODE_REMOTE_OPEN_HOST first among the SSH hosts for
          # remote "open in editor" links; clients use the first entry.
          openFiles=$(grep -rlF 'const shortHostname = (yield* Hostname)' \
            "$out/lib/t3code/apps/server/dist" || true)
          if [ -z "$openFiles" ]; then
            echo "t3code-server: remote open targets not found; update the remote open patch" >&2
            exit 1
          fi
          for file in $openFiles; do
            substituteInPlace "$file" \
              --replace-fail 'const shortHostname = (yield* Hostname)' \
                             'const remoteOpenHost = process.env.T3CODE_REMOTE_OPEN_HOST?.trim(); if (remoteOpenHost) targets.unshift({ kind: "mdns", host: remoteOpenHost }); const shortHostname = (yield* Hostname)'
          done
        '';
      });
    };

    systemd.user.services.t3code-server.environment = mkIf (cfg.remoteOpenHost != null) {
      T3CODE_REMOTE_OPEN_HOST = cfg.remoteOpenHost;
    };

    # Start the user service at boot, without an active login session.
    users.users.${username}.linger = true;
  };
}
