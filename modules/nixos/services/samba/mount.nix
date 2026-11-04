{
  config,
  lib,
  pkgs,
  utils,
  ...
}:

with lib;

let
  cfg = config.modules.services.samba.mount;

  # "//neo.netbird.cloud/blockade" -> "neo.netbird.cloud"
  hostOf = device: head (filter (s: s != "") (splitString "/" device));

  unitOf = mountPoint: "${utils.escapeSystemdPath mountPoint}.mount";

  mountOptions =
    m:
    [
      "credentials=${m.credentialsFile}"
      "vers=3.1.1"
      "iocharset=utf8"

      # The server runs every operation as the authenticated user and keeps
      # the real owners and modes. Locally everything shows as uid/gid with
      # fixed modes; chmod/chown here never reach the server's permissions.
      "uid=${toString m.uid}"
      "gid=${toString m.gid}"
      "forceuid"
      "forcegid"
      "file_mode=${m.fileMode}"
      "dir_mode=${m.dirMode}"
      "nounix"

      # Mounted only by the watcher below, never on access, so a file
      # manager touching the directory can never block on a dead host
      "noauto"
      "nofail"
      "_netdev"
      "x-systemd.mount-timeout=10s"

      # If the host disappears while mounted, fail calls instead of hanging,
      # and notice a dead connection within ~10s
      "soft"
      "echo_interval=5"
    ]
    ++ optional m.readOnly "ro";

  # One line per mount: <mount point> <host> <unit>
  mountTable = concatStringsSep "\n" (
    mapAttrsToList (mp: m: "${mp} ${hostOf m.device} ${unitOf mp}") cfg.mounts
  );

  watcher = pkgs.writeShellApplication {
    name = "samba-mount-watch";
    runtimeInputs = with pkgs; [
      bash
      coreutils
      util-linux
      systemd
    ];
    text = ''
      reachable() {
        timeout 3 bash -c "exec 3<>/dev/tcp/$1/445" 2>/dev/null
      }

      while read -r mp host unit; do
        [ -n "$mp" ] || continue
        if mountpoint -q "$mp"; then
          if ! reachable "$host"; then
            echo "$host unreachable, detaching $mp"
            # Lazy + forced: returns immediately even if the share is hung
            umount -f -l "$mp" || true
            systemctl reset-failed "$unit" 2>/dev/null || true
          fi
        elif reachable "$host"; then
          echo "$host reachable, mounting $mp"
          systemctl reset-failed "$unit" 2>/dev/null || true
          systemctl start --no-block "$unit" || true
        fi
      done <<'EOF'
      ${mountTable}
      EOF
    '';
  };

in
{
  #============================================================================
  # OPTIONS
  #============================================================================
  options.modules.services.samba.mount = {
    enable = mkEnableOption "SMB share mounting";

    checkInterval = mkOption {
      type = types.str;
      default = "20s";
      description = ''
        How often to check each share's host. Reachable hosts get mounted,
        unreachable ones get detached so the directory shows empty instead of
        hanging.
      '';
    };

    mounts = mkOption {
      default = { };
      description = "SMB shares to mount, keyed by local mount point.";
      example = {
        "/mnt/neo/blockade".device = "//neo.netbird.cloud/blockade";
      };
      type = types.attrsOf (
        types.submodule {
          options = {
            device = mkOption {
              type = types.str;
              description = "UNC path of the share, e.g. //neo.netbird.cloud/blockade.";
            };
            credentialsFile = mkOption {
              type = types.str;
              default = config.sops.templates."samba-credentials".path;
              defaultText = literalExpression ''config.sops.templates."samba-credentials".path'';
              description = "File with username= and password= lines.";
            };
            uid = mkOption {
              type = types.int;
              default = 1000;
              description = "Local owner shown for every file.";
            };
            gid = mkOption {
              type = types.int;
              default = 100;
              description = "Local group shown for every file.";
            };
            fileMode = mkOption {
              type = types.str;
              default = "0660";
              description = "Local mode shown for files (display and local access check only).";
            };
            dirMode = mkOption {
              type = types.str;
              default = "0770";
              description = "Local mode shown for directories (display and local access check only).";
            };
            readOnly = mkOption {
              type = types.bool;
              default = false;
              description = "Mount read-only.";
            };
          };
        }
      );
    };
  };

  #============================================================================
  # CONFIG
  #============================================================================
  config = mkIf (cfg.enable && cfg.mounts != { }) {
    fileSystems = mapAttrs (_: m: {
      inherit (m) device;
      fsType = "cifs";
      options = mountOptions m;
    }) cfg.mounts;

    # The watcher starts these repeatedly; never let systemd's start limit
    # lock a mount out
    systemd.units = mapAttrs' (
      mp: _:
      nameValuePair (unitOf mp) {
        overrideStrategy = "asDropin";
        text = ''
          [Unit]
          StartLimitIntervalSec=0
        '';
      }
    ) cfg.mounts;

    systemd.services.samba-mount-watch = {
      description = "Mount reachable Samba shares, detach unreachable ones";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = getExe watcher;
      };
    };

    systemd.timers.samba-mount-watch = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "15s";
        OnUnitActiveSec = cfg.checkInterval;
        AccuracySec = "1s";
      };
    };
  };
}
