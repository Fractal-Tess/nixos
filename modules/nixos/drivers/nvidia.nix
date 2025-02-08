{ config, lib, pkgs, ... }:

with lib;

let cfg = config.modules.hardware.nvidia;
in {
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
        description =
          "Enable fine-grained power management for modern NVIDIA GPUs";
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
      defaultText =
        literalExpression "config.boot.kernelPackages.nvidiaPackages.stable";
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
      # package = cfg.package;

      package =
        let
          rcu_patch = pkgs.fetchpatch {
            url =
              "https://github.com/gentoo/gentoo/raw/c64caf53/x11-drivers/nvidia-drivers/files/nvidia-drivers-470.223.02-gpl-pfn_valid.patch";
            hash = "sha256-eZiQQp2S/asE7MfGvfe6dA/kdCvek9SYa/FFGp24dVg=";
          };
        in
        config.boot.kernelPackages.nvidiaPackages.mkDriver {
          version = "535.154.05";
          sha256_64bit = "sha256-fpUGXKprgt6SYRDxSCemGXLrEsIA6GOinp+0eGbqqJg=";
          sha256_aarch64 = "sha256-G0/GiObf/BZMkzzET8HQjdIcvCSqB1uhsinro2HLK9k=";
          openSha256 = "sha256-wvRdHguGLxS0mR06P5Qi++pDJBCF8pJ8hr4T8O6TJIo=";
          settingsSha256 = "sha256-9wqoDEWY4I7weWW05F4igj1Gj9wjHsREFMztfEmqm10=";
          persistencedSha256 =
            "sha256-d0Q3Lk80JqkS1B54Mahu2yY/WocOqFFbZVBh+ToGhaE=";

          #version = "550.40.07";
          #sha256_64bit = "sha256-KYk2xye37v7ZW7h+uNJM/u8fNf7KyGTZjiaU03dJpK0=";
          #sha256_aarch64 = "sha256-AV7KgRXYaQGBFl7zuRcfnTGr8rS5n13nGUIe3mJTXb4=";
          #openSha256 = "sha256-mRUTEWVsbjq+psVe+kAT6MjyZuLkG2yRDxCMvDJRL1I=";
          #settingsSha256 = "sha256-c30AQa4g4a1EHmaEu1yc05oqY01y+IusbBuq+P6rMCs=";
          #persistencedSha256 = "sha256-11tLSY8uUIl4X/roNnxf5yS2PQvHvoNjnd2CB67e870=";

          patches = [ rcu_patch ];
        };
    };
  };
}
