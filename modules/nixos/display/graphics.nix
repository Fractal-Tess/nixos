{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    services.xserver.videoDrivers = mkDefault [ "nvidia" "amdgpu" ];
    hardware.graphics = {
      enable = mkDefault true;
      enable32Bit = mkDefault true;
      extraPackages = mkDefault [ ];
      extraPackages32 = mkDefault [ ];
    };
  };
}
