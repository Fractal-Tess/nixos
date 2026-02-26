{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.modules.tools.kimi-cli;
in
{
  options.modules.tools.kimi-cli = {
    enable = mkEnableOption "Kimi CLI - AI coding assistant from Moonshot AI";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.kimi-cli
      pkgs.ripgrep
    ];
  };
}
