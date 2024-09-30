{ config, lib, ... }:

with lib;

let
  cfg = config.modules.programs.direnv;
in
{
  options.modules.programs.direnv = {
    enable = mkEnableOption "Direnv";
    enableZshIntegration = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Zsh integration";
    };
  };

  config = mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableZshIntegration = cfg.enableZshIntegration;
    };
  };
}
