# modules/nixos/services/smb-mounts.nix
# Usage: import this file as a function and pass a 'shares' list argument.
# Each share should be an attrset with mountPoint, device, username, password, and optionally uid/gid.
{ shares }: {
  fileSystems = builtins.listToAttrs (map
    (share: {
      name = share.mountPoint;
      value = {
        device = share.device;
        fsType = "cifs";
        options = [
          "username=${share.username}"
          "password=${share.password}"
          "uid=${toString (share.uid or 1000)}"
          "gid=${toString (share.gid or 100)}"
          "iocharset=utf8"
          "vers=3.0"
          "rw"
        ];
      };
    })
    shares);
}
