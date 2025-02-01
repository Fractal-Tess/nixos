{ config, lib, ... }:

with lib;

let cfg = config.modules.programs.browsers;
in {
  options.modules.programs.browsers = { enable = mkEnableOption "Browsers"; };

  config = mkIf cfg.enable {

    environment.systemPackages = with pkgs; [
      microsoft-edge # Edge browser
      google-chrome # Chrome browser
      firefox # Firefox
      # TODO: Add tor, zen
    ];
  };
}
