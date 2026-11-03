{
  config,
  lib,
  username,
  ...
}:

with lib;

let
  cfg = config.modules.services.sops.samba;
in
{
  #============================================================================
  # OPTIONS
  #============================================================================
  options.modules.services.sops.samba = {
    enable = mkEnableOption "Samba password for the ${username} share user via SOPS" // {
      default = true;
    };
  };

  #============================================================================
  # CONFIG
  #============================================================================
  # Root-only: read by the share's smbpasswd sync on the server and by
  # mount.cifs on clients. Never exported to the shell.
  config = mkIf (config.modules.services.sops.enable && cfg.enable) {
    sops.secrets.samba_password = {
      sopsFile = ../../../../secrets/samba.json;
      format = "json";
      key = "password";
    };

    sops.templates."samba-credentials" = {
      mode = "0400";
      content = ''
        username=${username}
        password=${config.sops.placeholder.samba_password}
      '';
    };
  };
}
