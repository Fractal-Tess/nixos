{ config, lib, ... }:

with lib;

let
  cfg = config.modules.services.auto_cpu;
in
{
  options.modules.services.auto_cpu = {
    enable = mkEnableOption "Enable Auto CPU frequency";
    # create options for charger and battery

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

    # bluez
    # bluetuith
    # bluez
    # bluez-tools
    # obex_data_server

    # Bluetooth
    services.blueman.enable = false;
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          ControllerMode = "bredr";
          AutoEnable = "true";
          AutoConnect = "true";
          MultiProfile = "multiple";
          Enable = "Source,Sink,Media,Socket";
          Experimental = "true";
        };
      };
    };
  };
}
