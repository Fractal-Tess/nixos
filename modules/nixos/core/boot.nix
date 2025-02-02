{ config, lib, pkgs, ... }:
with lib;
let cfg = config.modules.boot;
in {
  options.modules.boot = {
    useCustomConfig = mkOption {
      type = types.bool;
      default = false;
      description =
        "Whether to use the custom boot configuration. If false, it will use NixOS defaults.";
    };

    loader = {
      efi = {
        canTouchEfiVariables = mkOption {
          type = types.bool;
          default = true;
          description = "Whether the EFI variables can be modified.";
        };
      };

      grub = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Whether to use GRUB as the boot loader.";
        };
        device = mkOption {
          type = types.str;
          default = "nodev";
          description = "The device where GRUB should be installed.";
        };
        efiSupport = mkOption {
          type = types.bool;
          default = true;
          description = "Whether to enable EFI support in GRUB.";
        };
        useOSProber = mkOption {
          type = types.bool;
          default = true;
          description =
            "Whether to use OS-prober to detect other operating systems.";
        };
        theme = mkOption {
          type = types.str;
          default = "${pkgs.libsForQt5.breeze-grub}/grub/themes/breeze";
          description = "The theme to use for GRUB.";
        };
      };
    };

    supportedFilesystems = mkOption {
      type = types.listOf types.str;
      default = [ "ntfs" ];
      description = "List of filesystems to support during boot.";
    };
  };

  config = mkMerge [
    (mkIf cfg.useCustomConfig {
      boot = {
        loader = {
          efi.canTouchEfiVariables = cfg.loader.efi.canTouchEfiVariables;
          grub = {
            enable = cfg.loader.grub.enable;
            device = cfg.loader.grub.device;
            efiSupport = cfg.loader.grub.efiSupport;
            useOSProber = cfg.loader.grub.useOSProber;
            theme = cfg.loader.grub.theme;
          };
        };
        supportedFilesystems = cfg.supportedFilesystems;
      };
    })

    (mkIf (!cfg.useCustomConfig) {
      boot.loader.systemd-boot.enable = mkDefault true;
      boot.loader.efi.canTouchEfiVariables = mkDefault true;
    })
  ];
}
