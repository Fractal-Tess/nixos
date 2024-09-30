{ pkgs, ... }: {

  # Pulseaudio realtime
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    # Use jack in applications
    jack.enable = true;
  };

  hardware.pulseaudio = {
    enable = false;
    daemon.config = {
      flat-volumes = "yes";
    };
  };

}
