{ config, lib, pkgs, ... }:

with lib;

{
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
