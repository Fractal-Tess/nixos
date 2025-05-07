{ config, lib, pkgs, ... }:

with lib;

let cfg = config.modules.services.auto_cpu;
in {
  options.modules.services.auto_cpu = {
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

  config = mkIf cfg.enable {
    services.auto-cpufreq = {
      enable = true;
      settings = {
        charger = {
          governor = cfg.charger.governor;
          turbo = cfg.charger.turbo;
        };
        battery = {
          governor = cfg.battery.governor;
          turbo = cfg.battery.turbo;
        };
      };
    };
  };
}
