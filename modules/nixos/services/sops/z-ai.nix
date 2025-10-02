{ config, lib, username, ... }:

with lib;

let cfg = config.modules.services.sops.z_ai;
in {
  options.modules.services.sops.z_ai = {
    enable = mkEnableOption "Z-AI secrets management via SOPS";
  };

  config = mkIf (config.modules.services.sops.enable && cfg.enable) {
    sops.secrets = {
      api_key = {
        owner = username;
        sopsFile = ../../../../secrets/z-ai.yaml;
        format = "yaml";
        path = "/home/${username}/.config/secrets/z-ai.apikey";
      };
    };
  };
}
