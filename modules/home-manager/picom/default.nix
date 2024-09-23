{ ... }: {
  services.picom = {
    enable = true;
    activeOpacity = 1.0;
    # inactiveOpacity = 0.85;
    inactiveOpacity = 1.0;
    shadow = true;
    backend = "glx";
    settings = {
      vsync = true;
      glx-copy-from-front = true;
      glx-swap-method = 2;
      xrendr-sync = true;
      xrender-sync-fence = true;
      method = "guassian";
      size = 10;
      deviation = 5.0;
      # blur-background = true;
      # blur-background-frame = true;
      # blur-background-fixed = true;
      corner-radius = 8;
    };
    opacityRules = [
      # "70:class_g = 'kitty'"
      "100:class_g = 'Google-chrome'"
      "100:class_g = 'Rofi'"
      # TODO: Fix these matchers
      "100:class_g *?= 'vlc'"
      "100:class_g *?= 'mpv'"
      "100:name *?= 'youtube'"
    ];
  };

}
