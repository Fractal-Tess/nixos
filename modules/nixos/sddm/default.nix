{ ... }: {
  services.xserver.displayManager.sddm = {
    enable = true;
    theme = "~/nixos/modules/nixos/sddm/sugar-dark";
  };
}
