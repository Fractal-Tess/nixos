{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [ qt5.qtgraphicaleffects ];
  services.displayManager.sddm = {
    enable = true;
    theme = "/sddm-themes/sugar-dark/";
  };
}
