{ ... }: {
  services.xserver.displayManager.sddm = {
    enable = true;
    theme = "/home/fractal-tess/nixos/modules/nixos/sddm/sugar-dark";
  };
}
