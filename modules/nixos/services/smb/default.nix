{ config, lib, ... }:
with lib;
let cfg = config.modules.filesystems.smb;
in {
  options.modules.filesystems.smb = {
    enable = mkEnableOption "SMB/CIFS share mounting";
    shares = mkOption {
      type = with types;
        listOf (submodule {
          options = {
            mountPoint = mkOption { type = str; };
            device = mkOption { type = str; };
            username = mkOption { type = str; };
            password = mkOption { type = str; };
            uid = mkOption {
              type = nullOr int;
              default = 1000;
            };
            gid = mkOption {
              type = nullOr int;
              default = 100;
            };
          };
        });
      default = [ ];
      description = "List of SMB shares to mount.";
    };
  };

  config = mkIf cfg.enable {
    fileSystems = listToAttrs (map
      (share: {
        name = share.mountPoint;
        value = {
          device = share.device;
          fsType = "cifs";
          options = [
            "username=${share.username}"
            "password=${share.password}"
            "uid=${toString share.uid}"
            "gid=${toString share.gid}"
            "iocharset=utf8"
            "vers=3.0"
            "rw"
            "x-systemd.automount"
            "x-systemd.device-timeout=10"
          ];
        };
      })
      cfg.shares);
  };
}
