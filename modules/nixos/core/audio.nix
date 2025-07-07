{ config, lib, pkgs, ... }:

with lib;

{
  # Audio configuration module
  # This module configures the audio system using PipeWire as the primary audio server
  # with ALSA, PulseAudio, and JACK support. It also includes essential audio utilities.
  config = {
    # Enable real-time scheduling for audio applications
    security.rtkit.enable = mkDefault true;

    # Install essential audio control utilities
    environment.systemPackages =
      mkMerge [ (with pkgs; [ playerctl pamixer pavucontrol ]) ];

    # Configure PipeWire as the main audio server
    services.pipewire = {
      enable = mkDefault true;
      # Enable ALSA compatibility layer
      alsa = {
        enable = mkDefault true;
        support32Bit = true;
      };
      # Enable PulseAudio compatibility layer
      pulse.enable = mkDefault true;
      # Enable JACK compatibility layer for professional audio
      jack.enable = mkDefault true;
    };

    # Disable the standalone PulseAudio service since PipeWire provides compatibility
    services.pulseaudio = {
      enable = mkDefault false;
      daemon.config = { flat-volumes = mkDefault "yes"; };
    };
  };
}
