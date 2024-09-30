{ config, lib, ... }:

with lib;

let
  cfg = config.modules.hardware.nvidia;
in
{
  options.modules.hardware.nvidia = {
    enable = mkEnableOption "NVIDIA configuration";

    modesetting.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable modesetting for NVIDIA";
    };

    powerManagement = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable NVIDIA power management (experimental)";
      };

      finegrained = mkOption {
        type = types.bool;
        default = false;
        description = "Enable fine-grained power management for modern NVIDIA GPUs";
      };
    };

    open = mkOption {
      type = types.bool;
      default = false;
      description = "Use the NVIDIA open source kernel module";
    };

    nvidiaSettings = mkOption {
      type = types.bool;
      default = true;
      description = "Enable the NVIDIA settings menu";
    };

    package = mkOption {
      type = types.package;
      default = config.boot.kernelPackages.nvidiaPackages.stable;
      defaultText = literalExpression "config.boot.kernelPackages.nvidiaPackages.stable";
      description = "NVIDIA driver package to use";
    };
  };

  config = mkIf cfg.enable {
    hardware.nvidia = {
      modesetting.enable = cfg.modesetting.enable;
      powerManagement = {
        enable = cfg.powerManagement.enable;
        finegrained = cfg.powerManagement.finegrained;
      };
      open = cfg.open;
      nvidiaSettings = cfg.nvidiaSettings;
      package = cfg.package;
    };
  };
}
