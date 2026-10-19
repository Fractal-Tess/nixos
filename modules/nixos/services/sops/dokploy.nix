{
  config,
  lib,
  username,
  ...
}:

with lib;

let
  cfg = config.modules.services.sops.dokploy;
in
{
  options.modules.services.sops.dokploy = {
    enable = mkEnableOption "Dokploy API key management via SOPS";
  };

  config = mkIf (config.modules.services.sops.enable && cfg.enable) {
    systemd.tmpfiles.rules = [
      "d /home/${username}/.secrets.d 0755 ${username} users -"
    ];

    sops.secrets.dokploy_api_key = {
      owner = username;
      group = username;
      sopsFile = ../../../../secrets/dokploy-fractal-tess.json;
      format = "json";
      key = "API_KEY";
    };

    sops.templates."dokploy.fish" = {
      owner = username;
      group = username;
      mode = "0600";
      path = "/home/${username}/.secrets.d/dokploy.fish";
      content = ''
        set -gx DOKPLOY_URL "https://dokploy.fractal-tess.xyz"
        set -gx DOKPLOY_API_KEY "${config.sops.placeholder.dokploy_api_key}"
      '';
    };
  };
}
