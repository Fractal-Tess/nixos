{ config, lib, ... }:

with lib;

let cfg = config.modules.services.samba.mount;

in {
  options.modules.services.samba.mount = {
    enable = mkEnableOption "SMB/CIFS share mounting";
    shares = mkOption {
      type = with types;
        listOf (submodule {
          options = {
            mountPoint = mkOption {
              type = str;
              description = ''
                The local mount point for the SMB share.
                Example: "/mnt/share".
              '';
            };
            device = mkOption {
              type = str;
              description = ''
                The UNC path to the SMB/CIFS share.
                Example: "//server/share".
              '';
            };
            username = mkOption {
              type = str;
              description = ''
                The username to use for authenticating to the SMB share.
                Ignored if credentialsFile is set.
              '';
              default = "";
            };
            password = mkOption {
              type = str;
              description = ''
                The password to use for authenticating to the SMB share.
                Ignored if credentialsFile is set.
                Note: Storing passwords in Nix configs is insecure. Use with caution.
              '';
              default = "";
            };
            credentialsFile = mkOption {
              type = nullOr str;
              default = null;
              description = ''
                Path to a file containing SMB credentials in the format:
                  username=USER
                  password=PASS
                If set, this file will be used for authentication instead of username/password options.
                Example: "/etc/nixos/smb-secrets"
              '';
            };
            uid = mkOption {
              type = nullOr int;
              default = 1000;
              description = ''
                The local user ID that will own the mounted files.
                Default: 1000 (typically the first user account).
              '';
            };
            gid = mkOption {
              type = nullOr int;
              default = 100;
              description = ''
                The local group ID that will own the mounted files.
                Default: 100 (typically the "users" group).
              '';
            };
          };
        });
      default = [ ];
      description =
        "List of SMB shares to mount. Each entry defines a share to be mounted.";
    };
  };

  config = mkIf cfg.enable {
    # For each share, create a fileSystems entry for mounting via systemd automount
    fileSystems = listToAttrs (map (share: {
      name = share.mountPoint;
      value = {
        device = share.device;
        fsType = "cifs";
        options =
          # If credentialsFile is set, use it; otherwise, use username/password
          let
            baseOptions = [
              # Set file ownership
              "uid=${toString share.uid}"
              "gid=${toString share.gid}"
              # Use UTF-8 encoding for file names
              "iocharset=utf8"
              # Use SMB protocol version 3.0
              "vers=3.0"
              # Mount read-write
              "rw"
              # Use systemd automount for on-demand mounting
              "x-systemd.automount"
              # Do not mount automatically
              "noauto"
              # Do not fail if the share is unavailable (prevents boot/activation failure)
              "nofail"
              # Idle timeout
              "x-systemd.idle-timeout=60s"
              # Set device timeout
              "x-systemd.device-timeout=5s"
              # Limit mount attempts to 5 seconds to avoid long waits
              "x-systemd.mount-timeout=5s"
            ];
          in if share.credentialsFile != null then
            [ "credentials=${share.credentialsFile}" ] ++ baseOptions
          else
            [ "username=${share.username}" "password=${share.password}" ]
            ++ baseOptions;
      };
    }) cfg.shares);
  };
}
