{ config, lib, pkgs, ... }:

with lib;

{
  imports = [
    ./adb/default.nix
    ./auto_cpu/default.nix
    ./filesystemExtraServices/default.nix
    ./sshd/default.nix
    ./docker/default.nix
    ./smb/default.nix
  ];
}
