{ config, lib, ... }:

with lib;

let cfg = config.modules.services.automount;
in {
  options.modules.services.automount = { enable = mkEnableOption "Automount"; };

  config = mkIf cfg.enable {
    services.udisks2.enable = true;
    services.devmon.enable = true;
    services.gvfs.enable = true;
  };
}
