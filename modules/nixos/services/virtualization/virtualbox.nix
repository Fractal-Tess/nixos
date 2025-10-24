{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.services.virtualization.virtualbox;
in
{
  options.modules.services.virtualization.virtualbox = {
    enable = mkEnableOption "VirtualBox virtualization";

    host = {
      enable = mkEnableOption "VirtualBox host support";

      enableKvm = mkOption {
        type = types.bool;
        default = true;
        description = "Enable KVM acceleration for VirtualBox";
      };

      enableExtensionPack = mkOption {
        type = types.bool;
        default = true;
        description = "Enable VirtualBox Extension Pack for USB 2.0/3.0, RDP, and PXE boot";
      };

      enableHardening = mkOption {
        type = types.bool;
        default = true;
        description = "Enable hardening for VirtualBox";
      };

      headless = mkOption {
        type = types.bool;
        default = false;
        description = "Run VirtualBox in headless mode";
      };

      enableWebService = mkOption {
        type = types.bool;
        default = false;
        description = "Enable VirtualBox web service for remote management";
      };

      addNetworkInterface = mkOption {
        type = types.bool;
        default = true;
        description = "Add default network interface";
      };
    };

    guest = {
      enable = mkEnableOption "VirtualBox guest additions";

      verbose = mkOption {
        type = types.bool;
        default = false;
        description = "Enable verbose logging for guest additions";
      };

      seamless = mkOption {
        type = types.bool;
        default = true;
        description = "Enable seamless mode for guest additions";
      };

      dragAndDrop = mkOption {
        type = types.bool;
        default = true;
        description = "Enable drag and drop for guest additions";
      };

      clipboard = mkOption {
        type = types.bool;
        default = true;
        description = "Enable shared clipboard for guest additions";
      };

      vboxsf = mkOption {
        type = types.bool;
        default = true;
        description = "Enable shared folder support for guest additions";
      };
    };

    package = mkOption {
      type = types.package;
      default = pkgs.virtualbox;
      description = "VirtualBox package to use";
    };
  };

  config = mkIf (cfg.host.enable || cfg.guest.enable) {
    # Virtualization support
    virtualisation.virtualbox.host = mkIf cfg.host.enable {
      enable = true;
      enableKvm = cfg.host.enableKvm;
      enableExtensionPack = cfg.host.enableExtensionPack;
      enableHardening = cfg.host.enableHardening;
      headless = cfg.host.headless;
      enableWebService = cfg.host.enableWebService;
      addNetworkInterface = cfg.host.addNetworkInterface;
      package = cfg.package;
    };

    # Guest additions
    virtualisation.virtualbox.guest = mkIf cfg.guest.enable {
      enable = true;
      verbose = cfg.guest.verbose;
      vboxsf = cfg.guest.vboxsf;
      seamless = cfg.guest.seamless;
      dragAndDrop = cfg.guest.dragAndDrop;
      clipboard = cfg.guest.clipboard;
    };

    # Add user to vboxusers group for USB access
    users.groups.vboxusers = mkIf cfg.host.enable {};

    # Add current user to vboxusers group
    users.users.${config.modules.username or "root"} = mkIf cfg.host.enable {
      extraGroups = [ "vboxusers" ];
    };

    # BOINC integration if enabled
    services.boinc.extraEnvPackages = mkIf cfg.host.enable [ cfg.package ];
  };
}