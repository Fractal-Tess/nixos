{ config, username, lib, ... }:

with lib;

let cfg = config.modules.security;

in {
  options.modules.security = {
    noSudoPassword =
      mkEnableOption "Remove the need for password when using sudo";
  };

  config = {
    security.sudo.extraRules = [{
      users = [ username ];
      commands = [{
        # Removes the need for a password when using sudo
        command = mkDefault "ALL";
        options = mkMerge [
          (if config.modules.security.noSudoPassword then
            [ "NOPASSWD" ]
          else
            [ ])
        ];
      }];
    }];

  };
}
