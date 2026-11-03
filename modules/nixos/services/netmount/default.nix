{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.modules.services.netmount;

  mountOptions =
    m:
    [
      # Mount on first access, unmount after idle, never block boot
      "x-systemd.automount"
      "noauto"
      "nofail"
      "_netdev"
      "x-systemd.idle-timeout=${m.idleTimeout}"
      "x-systemd.mount-timeout=20s"
      "x-systemd.after=network-online.target"
      "x-systemd.after=netbird.service"

      # Every operation runs on the remote host as `user` over SFTP, so the
      # remote kernel enforces that user's permissions. Ownership and modes are
      # passed through unchanged: no forced owner, no create masks, no uid/gid
      # rewriting. chown from the client fails, the same as it would over SSH.
      "allow_other"
      "default_permissions"

      # Survive Wi-Fi drops and suspend instead of hanging
      "reconnect"
      "ServerAliveInterval=15"
      "ServerAliveCountMax=3"
      "ConnectTimeout=10"

      # Root performs the mount, but authenticates with the user's key and
      # trusts the user's known_hosts
      "IdentityFile=${m.identityFile}"
      "UserKnownHostsFile=${m.knownHostsFile}"
      "BatchMode=yes"
    ]
    ++ optional m.readOnly "ro";

in
{
  #============================================================================
  # OPTIONS
  #============================================================================
  options.modules.services.netmount = {
    enable = mkEnableOption "SSHFS network mounts of directories on other hosts";

    mounts = mkOption {
      default = { };
      description = ''
        Remote directories to mount, keyed by local mount point. Files keep
        their real owners and modes on the remote host.
      '';
      example = {
        "/mnt/blockade" = {
          host = "neo.netbird.cloud";
          remotePath = "/mnt/blockade";
        };
      };
      type = types.attrsOf (
        types.submodule {
          options = {
            host = mkOption {
              type = types.str;
              description = "Remote host to mount from.";
            };
            remotePath = mkOption {
              type = types.str;
              description = "Absolute path of the directory on the remote host.";
            };
            user = mkOption {
              type = types.str;
              default = "fractal-tess";
              description = "Remote user the mount acts as.";
            };
            identityFile = mkOption {
              type = types.str;
              default = "/home/fractal-tess/.ssh/id_ed25519";
              description = "Private key used to log in to the remote host.";
            };
            knownHostsFile = mkOption {
              type = types.str;
              default = "/home/fractal-tess/.ssh/known_hosts";
              description = "known_hosts file holding the remote host's key.";
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
    system.fsPackages = [ pkgs.sshfs ];

    fileSystems = mapAttrs (_: m: {
      device = "${m.user}@${m.host}:${m.remotePath}";
      fsType = "fuse.sshfs";
      options = mountOptions m;
    }) cfg.mounts;
  };
}
