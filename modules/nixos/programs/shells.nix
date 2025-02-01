{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.programs.zsh;
in
{
  options.modules.programs.zsh = {
    enable = mkEnableOption "Zsh";
  };

  config = mkIf cfg.enable {
    # Shell (zsh)
    programs.zsh.enable = true;
    environment.pathsToLink = [ "/share/zsh" ];
    users.defaultUserShell = pkgs.zsh;
  };
}
