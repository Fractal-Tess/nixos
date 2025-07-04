{ config, lib, ... }:

with lib;

let cfg = config.modules.services.samba.share;

in {
  options.modules.services.samba.share = {
    enable = mkEnableOption "Samba share service";
    shares = mkOption {
      type = with types;
        listOf (submodule {
          options = {
            name = mkOption {
              type = types.str;
              description = ''
                The name of the Samba share as it will appear to clients.
                Example: "public" or "myshare".
              '';
            };
            path = mkOption {
              type = types.str;
              description = ''
                The absolute path to the directory to export as a Samba share.
                Example: "/srv/samba/public".
              '';
            };
            validUsers = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = ''
                List of users allowed to access this share. If empty, no user restriction is applied.
                Example: [ "alice" "bob" ]
              '';
            };
            readOnly = mkOption {
              type = types.bool;
              default = false;
              description = ''
                Whether the share is read-only. If true, clients cannot write to the share.
                Default: false (read-write).
              '';
            };
            guestOk = mkOption {
              type = types.bool;
              default = false;
              description = ''
                Allow guest (unauthenticated) access to the share.
                Default: false. Set to true for public shares.
              '';
            };
            forceUser = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = ''
                If set, all file operations on the share will be performed as this user.
                Example: "nobody". Useful for public shares.
              '';
            };
            forceGroup = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = ''
                If set, all file operations on the share will be performed as this group.
                Example: "users".
              '';
            };
            createMask = mkOption {
              type = types.str;
              default = "0644";
              description = ''
                File creation mask (permissions) for new files created via Samba.
                Example: "0644" (rw-r--r--).
                Default: 0644.
              '';
            };
            directoryMask = mkOption {
              type = types.str;
              default = "0755";
              description = ''
                Directory creation mask (permissions) for new directories created via Samba.
                Example: "0755" (rwxr-xr-x).
                Default: 0755.
              '';
            };
            # Optionally set an initial SMB password for the share's users
            initialPassword = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = ''
                If set, will set the SMB password for all validUsers of this share to this value at activation time.
                WARNING: Storing passwords in plaintext is insecure. Use only for non-sensitive setups.
              '';
            };
          };
        });
      default = [ ];
      description = ''
        List of Samba shares to export. Each entry defines a share with its own settings.
      '';
    };
    openFirewall = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to automatically open the firewall for Samba ports (137-139, 445).
        Default: true. Set to false if you want to manage firewall rules manually.
      '';
    };
    extraGlobal = mkOption {
      type = types.attrs;
      default = { };
      description = ''
        Extra global Samba settings to merge into the [global] section of smb.conf.
        Example: { "max log size" = "1000"; }.
      '';
    };
  };

  config = mkIf cfg.enable {
    # Enable the Samba service and configure global settings
    services.samba = {
      enable = true;
      openFirewall = cfg.openFirewall;
      settings = ({
        global = {
          # Map unknown users to guest (never by default for security)
          "map to guest" = "never";
          # Server description string
          "server string" = "NixOS Samba Server";
          # Use user-level security
          security = "user";
          # Use the default Samba password backend
          "passdb backend" = "tdbsam";
        } // cfg.extraGlobal;
      }) // listToAttrs (map
        (share: {
          name = share.name;
          value = lib.filterAttrs (_: v: v != null) ({
            # Path to the shared directory
            path = share.path;
            # Make the share visible in network browsers
            browseable = "yes";
            # Set read-only or read-write
            "read only" = if share.readOnly then "yes" else "no";
            # Allow guest access if enabled
            "guest ok" = if share.guestOk then "yes" else "no";
            # Restrict access to valid users
            "valid users" = concatStringsSep " " share.validUsers;
            # Set file and directory creation masks
            "create mask" = share.createMask;
            "directory mask" = share.directoryMask;
          } // optionalAttrs (share.forceUser != null) {
            # Force all operations as this user
            "force user" = share.forceUser;
          } // optionalAttrs (share.forceGroup != null) {
            # Force all operations as this group
            "force group" = share.forceGroup;
          });
        })
        cfg.shares);
    };
    # Set SMB passwords for users with initialPassword set in any share
    system.activationScripts.sambaInitialPasswords =
      let
        # Collect all (user, password) pairs from shares with initialPassword
        userPwds = lib.flatten (map
          (share:
            if share.initialPassword != null then
              map
                (user: {
                  user = user;
                  password = share.initialPassword;
                })
                share.validUsers
            else
              [ ])
          cfg.shares);
        # Remove duplicates by user (last password wins)
        userPwdsUnique = lib.unique userPwds;
      in
      lib.mkIf (userPwdsUnique != [ ]) (lib.concatStringsSep "\n" ([
        "# Set initial SMB passwords for Samba users (auto-generated by Nix module)"
      ] ++ (map
        (entry:
          "(echo '${entry.password}'; echo '${entry.password}') | smbpasswd -s -a ${entry.user} || true")
        userPwdsUnique)));
  };
}
