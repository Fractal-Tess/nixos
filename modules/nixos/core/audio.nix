{ config, lib, pkgs, ... }:

with lib;
let cfg = config.modules.audio;

in {
  options.modules.audio = {
    # Automatically enable this if this is a desktop install
    # This can also manually be enabled by using "modules.audio.enable = true;"
    enable = mkEnableOption {
      default = true;
      description = "Enable audio configuration";
    };
  };

  config = {
    security.rtkit.enable = mkDefault true;

    environment.systemPackages =
      mkMerge [ (with pkgs; [ playerctl pamixer pavucontrol ]) ];

    services.pipewire = {
      enable = mkDefault true;
      alsa = {
        enable = mkDefault true;
        support32Bit = true;
      };
      pulse.enable = mkDefault true;
      jack.enable = mkDefault true;
    };

    services.pulseaudio = {
      enable = mkDefault false;
      daemon.config = { flat-volumes = mkDefault "yes"; };
    };
  };
}
