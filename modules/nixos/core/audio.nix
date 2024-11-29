{ config, lib, ... }:

with lib;

let
  cfg = config.modules.audio;
in
{
  options.modules.audio = {
    enable = mkEnableOption "Audio";

    # rtkit
    rtkit = mkOption {
      type = types.bool;
      default = true;
      description = "Audio servers like PulseAudio or PipeWire rely on rtkit to operate in real-time mode. They request real-time scheduling through rtkit to provide smooth and low-latency audio playback or recording.";
    };

    # PipeWire 
    pipeWire = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable pipewire";
      };


      # Jack
      jack = {
        enable =
          mkOption {
            type = types.bool;
            default = true;
            description = "Enable jack";
          };
      };

      # Pulse
      pulse = {
        enable =
          mkOption {
            type = types.bool;
            default = true;
            description = "Enable pulseaudio emulation";
          };
      };

      # Alsa
      alsa = {
        enable =
          mkOption {
            type = types.bool;
            default = true;
            description = "Enable alsa";
          };
      };
    };

    # PulseAudio 
    pulseAudio = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable pulseaudio";
      };

      #  Disables volume ramping
      flatVolumes = mkOption {
        type = types.enum [ "yes" "no" ];
        default = "yes";
        description = "Enable flat volumes";
      };
    };


  };

  config = mkIf cfg.enable {

    # Pulseaudio realtime priority
    security.rtkit.enable = cfg.rtkit;

    # PipeWire
    services.pipewire = {
      enable = cfg.pipeWire.enable;
      alsa = {
        enable = cfg.pipeWire.alsa.enable;
        support32Bit = true;
      };
      pulse.enable = cfg.pipeWire.pulse.enable;
      jack.enable = cfg.pipeWire.jack.enable;
    };

    # PulseAudio
    hardware.pulseaudio = {
      enable = cfg.pulseAudio.enable;
      daemon.config = {
        flat-volumes = cfg.pulseAudio.flatVolumes;
      };
    };
  };
}
