{
  config,
  lib,
  username,
  ...
}:

with lib;

let
  cfg = config.modules.services.samba.fleet;
  me = config.networking.hostName;

  own = cfg.hosts.${me} or { };
  others = removeAttrs cfg.hosts [ me ];
in
{
  #============================================================================
  # OPTIONS
  #============================================================================
  options.modules.services.samba.fleet = {
    enable = mkEnableOption ''
      fleet-wide Samba: share this host's entries from `hosts` and mount every
      other host's shares at /mnt/<host>/<share>
    '';

    hosts = mkOption {
      type = types.attrsOf (types.attrsOf types.str);
      default = {
        neo = {
          blockade = "/mnt/blockade";
          home = "/home/${username}";
        };
        vd = {
          vault = "/mnt/vault";
          home = "/home/${username}";
        };
      };
      description = "Per host: share name -> local path it exports.";
    };
  };

  #============================================================================
  # CONFIG
  #============================================================================
  config = mkIf cfg.enable {
    modules.services.samba.share = mkIf (own != { }) {
      enable = true;
      shares = mapAttrs (_: path: { inherit path; }) own;
    };

    modules.services.samba.mount = {
      enable = true;
      mounts = listToAttrs (
        concatLists (
          mapAttrsToList (
            host: shares:
            mapAttrsToList (
              name: _: nameValuePair "/mnt/${host}/${name}" { device = "//${host}.netbird.cloud/${name}"; }
            ) shares
          ) others
        )
      );
    };
  };
}
