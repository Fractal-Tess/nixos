{
  config,
  hostname,
  inputs,
  lib,
  pkgs,
  username,
  ...
}:

with lib;

let
  cfg = config.modules.services.fader;
in
{
  #============================================================================
  # IMPORTS
  #============================================================================
  imports = [ inputs.fader.nixosModules.default ];

  #============================================================================
  # OPTIONS
  #============================================================================
  options.modules.services.fader = {
    enable = mkEnableOption "fader on the NetBird mesh, controlling every other fleet host";

    hosts = mkOption {
      type = types.listOf types.str;
      default = [
        "vd"
        "kiwi"
      ];
      description = "Fleet hosts running fader. Each one lists all the others as peers.";
    };
  };

  #============================================================================
  # CONFIG
  #============================================================================
  # Full mesh: open http://<host>.netbird.cloud:7700 on any host to control
  # the audio of all of them. Offline peers show as unreachable in the app.
  config = mkIf cfg.enable {
    services.fader = {
      enable = true;
      package = inputs.fader.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.pkg-config ];
        buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.aws-lc ];
      });
      user = username;
      port = 7700;
      # Mesh only; every device on it is ours, so no token.
      firewallInterfaces = [ "wt0" ];
      settings.peers = map (name: {
        inherit name;
        url = "http://${name}.netbird.cloud:7700";
      }) (filter (name: name != hostname) cfg.hosts);
    };
  };
}
