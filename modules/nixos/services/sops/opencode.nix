{
  config,
  lib,
  username,
  ...
}:

with lib;

let
  cfg = config.modules.services.sops.opencode;
in
{
  options.modules.services.sops.opencode = {
    enable = mkEnableOption "OpenCode account keys management via SOPS";
  };

  config = mkIf (config.modules.services.sops.enable && cfg.enable) {
    systemd.tmpfiles.rules = [
      "d /home/${username}/.secrets.d 0755 ${username} users -"
    ];

    sops.secrets.opencode_vilian_gerdjikov = {
      owner = username;
      group = username;
      sopsFile = ../../../../secrets/opencode.json;
      key = "vilian.gerdjikov";
      format = "json";
    };

    sops.secrets.opencode_vgfractal = {
      owner = username;
      group = username;
      sopsFile = ../../../../secrets/opencode.json;
      key = "vgfractal";
      format = "json";
    };

    sops.templates."opencode.fish" = {
      owner = username;
      group = username;
      mode = "0600";
      path = "/home/${username}/.secrets.d/opencode.fish";
      content = ''
        set -gx OPENCODE_VILIAN_GERDJIKOV "${config.sops.placeholder.opencode_vilian_gerdjikov}"
        set -gx OPENCODE_VGFRACTAL "${config.sops.placeholder.opencode_vgfractal}"
      '';
    };
  };
}
