{ config, lib, pkgs, ... }:
with lib; {

  boot = {
    kernelPackages = mkDefault pkgs.linuxPackages_latest;

    loader = {
      efi.canTouchEfiVariables = mkDefault true;
      grub = {
        enable = mkDefault true;
        device = mkDefault "nodev";
        efiSupport = mkDefault true;
        useOSProber = mkDefault true;
        theme = mkDefault "${pkgs.kdePackages.breeze-grub}/grub/themes/breeze";
      };
    };
    supportedFilesystems = mkDefault [ "ntfs" ];
  };

}
