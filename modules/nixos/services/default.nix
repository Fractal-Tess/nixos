{ ... }:

{
  imports = [
    ./adb/default.nix
    ./auto_cpu/default.nix
    ./automount/default.nix
    ./remote-desktop/default.nix
    ./samba/default.nix
    ./sops/default.nix
    ./ssh/default.nix
    ./syncthing/default.nix
    ./virtualization/default.nix
  ];
}
