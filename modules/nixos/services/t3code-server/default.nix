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
      # `t3 auth session revoke`. --replace-fail breaks the build if upstream
      # moves the constant.
      package = upstreamPackage.overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          substituteInPlace "$out/lib/t3code/apps/server/dist/bin.mjs" \
            --replace-fail 'const DEFAULT_SESSION_TTL = days(30);' \
                           'const DEFAULT_SESSION_TTL = days(36500);'
        '';
      });
    };

    # Start the user service at boot, without an active login session.
    users.users.${username}.linger = true;
  };
}
