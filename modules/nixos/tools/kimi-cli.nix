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
    environment.systemPackages = with pkgs; [
      # Install uv package manager
      uv

      # Wrapper script for kimi-cli
      (writeShellScriptBin "kimi-cli" ''
        exec ${pkgs.uv}/bin/uv tool run --python 3.13 kimi-cli "$@"
      '')
    ];
  };
}
