{ config, lib, pkgs, ... }:
with lib; {

  boot = {
    kernelPackages = mkDefault pkgs.linuxPackages;

    loader = {
      efi.canTouchEfiVariables = mkDefault true;
      grub = {
        enable = mkDefault true;
        device = mkDefault "nodev";
        efiSupport = mkDefault true;
        useOSProber = mkDefault true;
        theme = mkDefault "${pkgs.libsForQt5.breeze-grub}/grub/themes/breeze";
      };
    };
    supportedFilesystems = mkDefault [ "ntfs" ];
  };

}
