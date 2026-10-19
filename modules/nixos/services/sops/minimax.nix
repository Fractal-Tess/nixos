{
  config,
  lib,
  username,
  ...
}:

with lib;

let
  cfg = config.modules.services.sops.minimax;
in
{
  options.modules.services.sops.minimax = {
    enable = mkEnableOption "Minimax secrets management via SOPS" // {
      default = true;
    };
  };

  config = mkIf (config.modules.services.sops.enable && cfg.enable) {

    systemd.tmpfiles.rules = [
      "d /home/${username}/.config/secrets/minimax 0755 ${username} users -"
      "d /home/${username}/.secrets.d 0755 ${username} users -"
    ];

    sops.secrets = {
      minimax_api_key = {
        owner = username;
        sopsFile = ../../../../secrets/minimax.json;
        format = "json";
        path = "/home/${username}/.config/secrets/minimax/apikey";
      };
    };

    sops.templates."minimax.fish" = {
      owner = username;
      group = username;
      mode = "0600";
      path = "/home/${username}/.secrets.d/minimax.fish";
      content = ''
        set -gx MINIMAX_API_KEY "${config.sops.placeholder.minimax_api_key}"
      '';
    };
  };
}
