{ lib, config, pkgs, ... }:

with lib;

{
  config = {
    services.xserver.videoDrivers = mkMerge [
      (mkIf config.modules.drivers.nvidia.enable [ "nvidia" ])
      (mkIf config.modules.drivers.amd.enable [ "amdgpu" ])
    ];
    hardware.graphics = {
      enable = mkDefault true;
      enable32Bit = mkDefault true;
      extraPackages = mkMerge [
        (mkIf config.modules.drivers.nvidia.enable [ ])
        (mkIf config.modules.drivers.amd.enable [ pkgs.amdvlk ])
      ];
      extraPackages32 = mkMerge [
        (mkIf config.modules.drivers.nvidia.enable [ ])
        (mkIf config.modules.drivers.amd.enable [ pkgs.amdvlk ])
      ];
    };
  };
}
