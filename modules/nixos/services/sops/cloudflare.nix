{
  config,
  lib,
  username,
  ...
}:

with lib;

let
  cfg = config.modules.services.sops.cloudflare;
in
{
  options.modules.services.sops.cloudflare = {
    enable = mkEnableOption "Cloudflare API token management via SOPS" // {
      default = true;
    };
  };

  config = mkIf (config.modules.services.sops.enable && cfg.enable) {
    systemd.tmpfiles.rules = [
      "d /home/${username}/.secrets.d 0755 ${username} users -"
    ];

    sops.secrets.cloudflare_api_token = {
      owner = username;
      group = username;
      sopsFile = ../../../../secrets/cloudflare.json;
      format = "json";
      key = "API_TOKEN";
    };

    sops.secrets.cloudflare_account_id = {
      owner = username;
      group = username;
      sopsFile = ../../../../secrets/cloudflare.json;
      format = "json";
      key = "ACCOUNT_ID";
    };

    # Names match what wrangler and the Cloudflare SDKs read.
    sops.templates."cloudflare.fish" = {
      owner = username;
      group = username;
      mode = "0600";
      path = "/home/${username}/.secrets.d/cloudflare.fish";
      content = ''
        set -gx CLOUDFLARE_API_TOKEN "${config.sops.placeholder.cloudflare_api_token}"
        set -gx CLOUDFLARE_ACCOUNT_ID "${config.sops.placeholder.cloudflare_account_id}"
      '';
    };
  };
}
