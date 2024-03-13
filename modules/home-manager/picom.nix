{ ... }: {
  services.picom = {
    enable = true;
    activeOpacity = 1.0;
    inactiveOpacity = 0.85;
    shadow = true;
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
    ];
  };

}
