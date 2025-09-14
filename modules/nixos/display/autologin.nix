{ config, lib, username, ... }:

with lib;

let
  cfg = config.modules.display.autologin;

in
{
  options.modules.display.autologin = {
    # Option to enable/disable autologin
    enable = mkEnableOption "automatic login";

    # Username to auto-login (defaults to the system username)
    user = mkOption {
      type = types.str;
      default = username;
      description = "Username to automatically login";
    };
  };

  # Configuration that applies when this module is enabled
  config = mkIf cfg.enable {
    # Enable automatic login for the specified user
    services.displayManager.autoLogin = {
      enable = true;
      user = cfg.user;
    };
  };
}