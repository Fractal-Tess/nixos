{ config, lib, username, ... }:

with lib;

let cfg = config.modules.services.sops.ssh;
in {
  options.modules.services.sops.ssh = {
    enable = mkEnableOption "SSH secrets management via SOPS";
  };

  config = mkIf (config.modules.services.sops.enable && cfg.enable) {
    sops.secrets = {
      ssh_authorized_keys = {
        owner = username;
        sopsFile = ../../../../secrets/ssh.yaml;
        format = "yaml";
        path = "/home/${username}/.ssh/authorized_keys";
      };
      ssh_config = {
        owner = username;
        sopsFile = ../../../../secrets/ssh.yaml;
        format = "yaml";
        path = "/home/${username}/.ssh/config";
      };
    };
  };
}
