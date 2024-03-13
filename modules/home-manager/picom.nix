{ ... }: {
  services.picom = {
    enable = true;
    activeOpacity = 1.0;
    inactiveOpacity = 0.85;
    shadow = true;
    backend = "glx";
    settings = {
      method = "guassian";
      size = 10;
      deviation = 5.0;
      # blur-background = true;
      blur-background-frame = true;
      blur-background-fixed = true;
      corner-radius = 8;
    };
    opacityRules = [
      "75:class_g = 'kitty'"
      # TODO: Fix these matchers
      "100:class_g *?= 'vlc'"
      "100:class_g *?= 'mpv'"
      "100:name *?= 'youtube'"
    ];
  };

}
