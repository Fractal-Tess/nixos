{ config, lib, ... }:
with lib;
let cfg = config.modules.services.samba-share;
in {
  options.modules.services.samba-share = {
    enable = mkEnableOption "Samba share service";
    shares = mkOption {
      type = with types;
        listOf (submodule {
          options = {
            name = mkOption {
              type = types.str;
              description = "Share name";
            };
            path = mkOption {
              type = types.str;
              description = "Path to share";
            };
            validUsers = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = "Valid users";
            };
            readOnly = mkOption {
              type = types.bool;
              default = false;
              description = "Read only";
            };
            guestOk = mkOption {
              type = types.bool;
              default = false;
              description = "Allow guest access";
            };
            forceUser = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Force user";
            };
            forceGroup = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Force group";
            };
            createMask = mkOption {
              type = types.str;
              default = "0644";
              description = "Create mask";
            };
            directoryMask = mkOption {
              type = types.str;
              default = "0755";
              description = "Directory mask";
            };
          };
        });
      default = [ ];
      description = "List of Samba shares to export.";
    };
    openFirewall = mkOption {
      type = types.bool;
      default = true;
      description = "Open firewall for Samba";
    };
    extraGlobal = mkOption {
      type = types.attrs;
      default = { };
      description = "Extra global Samba settings";
    };
  };

  config = mkIf cfg.enable {
    services.samba = {
      enable = true;
      openFirewall = cfg.openFirewall;
      settings = {
        global = {
          "map to guest" = "never";
          "server string" = "NixOS Samba Server";
          security = "user";
          "passdb backend" = "tdbsam";
        } // cfg.extraGlobal;
      };
      shares = listToAttrs (map (share: {
        name = share.name;
        value = {
          path = share.path;
          browseable = "yes";
          "read only" = if share.readOnly then "yes" else "no";
          "guest ok" = if share.guestOk then "yes" else "no";
          "valid users" = concatStringsSep " " share.validUsers;
          "force user" =
            if share.forceUser != null then share.forceUser else null;
          "force group" =
            if share.forceGroup != null then share.forceGroup else null;
          "create mask" = share.createMask;
          "directory mask" = share.directoryMask;
        };
      }) cfg.shares);
    };
  };
}
