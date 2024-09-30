{ config, lib, ... }:

with lib;

let
  cfg = config.modules.services.sshd;
in
{
  options.modules.services.sshd = {
    enable = mkEnableOption "SSH daemon";

    ports = mkOption {
      type = types.listOf types.int;
      default = [ 22 ];
      description = ''
        Ports to listen on.
      '';
    };

    settings = {
      PermitRootLogin = mkOption {
        type = types.str;
        default = "prohibit-password";
        description = ''
          Permit root login.
        '';
      };
      PasswordAuthentication = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Permit password authentication.
        '';
      };

    };
  };

  config = mkIf cfg.enable {
    services.openssh = {
      enable = true;
      ports = cfg.ports;
      settings = {
        PermitRootLogin = cfg.settings.PermitRootLogin;
        PasswordAuthentication = cfg.settings.PasswordAuthentication;
      };
    };
  };
}
