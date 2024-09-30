{ config, lib, ... }:

with lib;

let
  cfg = config.modules.programs.yazi;
in
{
  options.modules.programs.yazi = {
    enable = mkEnableOption "Yazi";
  };

  config = mkIf cfg.enable {
    programs.yazi = {
      enable = true;
    };
  };
}
