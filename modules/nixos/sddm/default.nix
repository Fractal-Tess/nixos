{ ... }: {
  services.xserver.displayManager.sddm = {
    enable = true;
    theme = "/sddm-themes/sugar-dark/";
  };
}
