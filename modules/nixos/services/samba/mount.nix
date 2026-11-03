{ config, lib, ... }:

with lib;

let
  cfg = config.modules.services.samba.mount;

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

      # Mount on first access, unmount after idle, never block boot or hang
      # forever when the server is offline
      "x-systemd.automount"
      "noauto"
      "nofail"
      "_netdev"
      "x-systemd.idle-timeout=${m.idleTimeout}"
      "x-systemd.mount-timeout=20s"
      "x-systemd.after=network-online.target"
      "x-systemd.after=netbird.service"
      "soft"
      "echo_interval=15"
    ]
    ++ optional m.readOnly "ro";

in
{
  #============================================================================
  # OPTIONS
  #============================================================================
  options.modules.services.samba.mount = {
    enable = mkEnableOption "SMB share mounting";

    mounts = mkOption {
      default = { };
      description = "SMB shares to mount, keyed by local mount point.";
      example = {
        "/mnt/blockade".device = "//neo.netbird.cloud/blockade";
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
            idleTimeout = mkOption {
              type = types.str;
              default = "10min";
              description = "Unmount after this long without access.";
            };
          };
        }
      );
    };
  };

  #============================================================================
  # CONFIG
  #============================================================================
  config = mkIf cfg.enable {
    fileSystems = mapAttrs (_: m: {
      inherit (m) device;
      fsType = "cifs";
      options = mountOptions m;
    }) cfg.mounts;
  };
}
