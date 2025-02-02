{ config, lib, pkgs, ... }:

with lib;

let cfg = config.modules.audio;
in {
  # Audio
  options.modules.audio = {

    # Audio is disabled by default
    enable = mkEnableOption "Audio";

    # RTKit
    rtkit = mkOption {
      type = types.bool;
      default = true;
      description =
        "Audio servers like PulseAudio or PipeWire rely on rtkit to operate in real-time mode. They request real-time scheduling through rtkit to provide smooth and low-latency audio playback or recording.";
    };

    # PipeWire
    pipeWire = {
      # PipeWire is enabled by default
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable pipewire";
      };

      # Jack
      jack = {
        # Jack is enabled by default
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable jack";
        };
      };

      # Pulse
      pulse = {
        # Pulse is enabled by default
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable pulseaudio emulation";
        };
      };

      # ALSA
      alsa = {
        # ALSA is enabled by default
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable alsa";
        };
      };
    };

    # PulseAudio
    pulseAudio = {
      # PulseAudio is disabled by default
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable pulseaudio";
      };

      # Flat volumes
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

    environment.systemPackages = with pkgs; [
      playerctl
      # pulseaudio 
      pamixer
      pavucontrol # Pulseaudio volume control
    ];

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
    services.pulseaudio = {
      enable = cfg.pulseAudio.enable;
      daemon.config = { flat-volumes = cfg.pulseAudio.flatVolumes; };
    };
  };
}
