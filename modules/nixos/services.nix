{ config, lib, pkgs, username, ... }:

with lib;

let cfg = config.modules.services;
in {
  options.modules.services = {
    enable = mkEnableOption "Services";

    adb = { enable = mkEnableOption "Android Debug Bridge"; };

    auto_cpu = {
      enable = mkEnableOption "Auto CPU frequency";
      charger = {
        governor = mkOption {
          type = types.string;
          default = "performance";
          description = "CPU governor to use when the laptop is plugged in";
        };

        turbo = mkOption {
          type = types.string;
          default = "always";
          description = "Turbo boost mode to use when the laptop is plugged in";
        };
      };

      battery = {
        governor = mkOption {
          type = types.string;
          default = "balanced";
          description = "CPU governor to use when the laptop is on battery";
        };

        turbo = mkOption {
          type = types.string;
          default = "auto";
          description = "Turbo boost mode to use when the laptop is on battery";
        };
      };
    };

    filesystemExtraServices = {
      enable = mkEnableOption "Filesystem utilities";
    };

    sshd = {
      enable = mkEnableOption "SSH daemon";
      ports = mkOption {
        type = types.listOf types.int;
        default = [ 22 ];
        description = "Ports to listen on.";
      };

      settings = {
        PermitRootLogin = mkOption {
          type = types.str;
          default = "prohibit-password";
          description = "Permit root login.";
        };
        PasswordAuthentication = mkOption {
          type = types.bool;
          default = false;
          description = "Permit password authentication.";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    # ADB Configuration
    programs.adb.enable = mkIf cfg.adb.enable true;
    services.udev.packages = with pkgs;
      (optionals cfg.adb.enable [ android-udev-rules ]);

    # Auto-CPU Configuration
    services.auto-cpufreq = mkIf cfg.auto_cpu.enable {
      enable = true;
      settings = {
        charger = {
          governor = cfg.auto_cpu.charger.governor;
          turbo = cfg.auto_cpu.charger.turbo;
        };
        battery = {
          governor = cfg.auto_cpu.battery.governor;
          turbo = cfg.auto_cpu.battery.turbo;
        };
      };
    };

    # All services configuration
    services = {
      # Filesystem Services Configuration
      udisks2.enable = mkIf cfg.filesystemExtraServices.enable true;
      devmon.enable = mkIf cfg.filesystemExtraServices.enable true;
      gvfs.enable = mkIf cfg.filesystemExtraServices.enable true;

      # SSH Configuration
      openssh = mkIf cfg.sshd.enable {
        enable = true;
        ports = cfg.sshd.ports;
        settings = {
          PermitRootLogin = cfg.sshd.settings.PermitRootLogin;
          PasswordAuthentication = cfg.sshd.settings.PasswordAuthentication;
        };
      };
    };
  };
}
