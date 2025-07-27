{ config, lib, username, ... }:

with lib;

let cfg = config.modules.services.sops.ssh;
in {
  options.modules.services.sops.ssh = {
    enable = mkEnableOption "SSH secrets management via SOPS";
    authorizedKeys = {
      enable = mkEnableOption "SSH authorized_keys management";
    };
    config = { enable = mkEnableOption "SSH config management"; };
  };

  config = mkIf (config.modules.services.sops.enable && cfg.enable) {
    sops.secrets = (lib.mkIf cfg.authorizedKeys.enable {
      ssh_authorized_keys = {
        owner = username;
        sopsFile = ../../../../secrets/ssh.yaml;
        format = "yaml";
        path = "/home/${username}/.ssh/authorized_keys";
      };
    }) // (lib.mkIf cfg.config.enable {
      ssh_config = {
        owner = username;
        sopsFile = ../../../../secrets/ssh.yaml;
        format = "yaml";
        path = "/home/${username}/.ssh/config";
      };
    });
  };
}
