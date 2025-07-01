{ ... }:

{
  imports = [
    ./adb/default.nix
    ./auto_cpu/default.nix
    ./automount/default.nix
    ./sshd/default.nix
    ./docker/default.nix
    ./smb/default.nix
    ./samba-share/default.nix
  ];
}
