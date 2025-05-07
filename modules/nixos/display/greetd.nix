{ config, lib, pkgs, username, ... }:

with lib;

let cfg = config.modules.display.greetd;
in {
  options.modules.display.greetd = {
    enable = mkEnableOption "Greetd display manager";

    autoLogin = mkEnableOption "Automatic login without password prompt";

    session = {
      command = mkOption {
        type = types.str;
        description = "Command to start the session";
        default = "";
      };

      user = mkOption {
        type = types.str;
        description = "User to automatically log in";
        default = username;
      };
    };
  };

  config = mkIf cfg.enable {
    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = mkIf (cfg.session.command != "") cfg.session.command;
        };

        initial_session = mkIf cfg.autoLogin {
          command = cfg.session.command;
          user = cfg.session.user;
        };
      };
    };
  };
}
