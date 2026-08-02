{
  config,
  lib,
  username,
  ...
}:

with lib;

let
  cfg = config.modules.services.sops.reactbits;
in
{
  options.modules.services.sops.reactbits = {
    enable = mkEnableOption "React Bits Pro license key management via SOPS";
  };

  config = mkIf (config.modules.services.sops.enable && cfg.enable) {
    sops.secrets.reactbits_license_key = {
      owner = username;
      group = username;
      sopsFile = ../../../../secrets/reactbits.json;
      format = "json";
    };

    sops.templates."reactbits.fish" = {
      owner = username;
      group = username;
      mode = "0600";
      path = "/home/${username}/.secrets.fish";
      content = ''
        set -gx REACTBITS_LICENSE_KEY "${config.sops.placeholder.reactbits_license_key}"
      '';
    };
  };
}
