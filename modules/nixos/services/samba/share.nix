{
  config,
  lib,
  username,
  ...
}:

with lib;

let
  cfg = config.modules.services.samba.share;
  samba = config.services.samba.package;

  # Per-share settings. Everything here exists so a client can read and write
  # as ${username} but can never alter the mode, owner or ACL of a file that
  # already exists. New files take their mode from the parent directory.
  shareSettings = share: {
    path = share.path;
    browseable = "yes";
    "read only" = if share.readOnly then "yes" else "no";
    "guest ok" = "no";

    # Only ${username} may connect. No force user/group: smbd runs as the
    # authenticated user, so the server kernel enforces normal permissions.
    "valid users" = username;

    # Clients cannot read or write NT ACLs, so no chmod/chown via ACL edits
    "nt acl support" = "no";
    "inherit acls" = "no";

    # DOS attributes (read-only, hidden, archive, system) go to an xattr.
    # Without this Samba falls back to chmod to represent them.
    "store dos attributes" = "yes";
    "map archive" = "no";
    "map hidden" = "no";
    "map system" = "no";
    "map readonly" = "no";
    "dos filemode" = "no";

    # New files and directories copy the parent directory's permissions
    # (files lose the execute bits); create/directory masks are not used.
    "inherit permissions" = "yes";

    # Do not let symlinks escape the share
    "follow symlinks" = "yes";
    "wide links" = "no";
  };

in
{
  #============================================================================
  # OPTIONS
  #============================================================================
  options.modules.services.samba.share = {
    enable = mkEnableOption "Samba shares that preserve existing ownership and permissions";

    shares = mkOption {
      default = { };
      description = "Directories to share, keyed by share name.";
      example = {
        blockade.path = "/mnt/blockade";
      };
      type = types.attrsOf (
        types.submodule {
          options = {
            path = mkOption {
              type = types.str;
              description = "Absolute path of the directory to share.";
            };
            readOnly = mkOption {
              type = types.bool;
              default = false;
              description = "Refuse all writes through this share.";
            };
          };
        }
      );
    };

    interface = mkOption {
      type = types.str;
      default = "wt0";
      description = "Only interface the firewall opens Samba on (NetBird).";
    };

    allowedNetwork = mkOption {
      type = types.str;
      default = "100.91.0.0/16";
      description = "Only network allowed to connect (the NetBird range).";
    };
  };

  #============================================================================
  # CONFIG
  #============================================================================
  config = mkIf cfg.enable {
    services.samba = {
      enable = true;
      openFirewall = false;
      nmbd.enable = false;
      winbindd.enable = false;

      settings = {
        global = {
          "server string" = config.networking.hostName;
          security = "user";
          "passdb backend" = "tdbsam";
          "map to guest" = "never";

          # NetBird only: the firewall opens 445 on the NetBird interface
          # alone and smbd refuses any other source address. Not binding to
          # the interface, because wt0 is point-to-point (smbd skips it) and
          # NetBird restarts would leave smbd without a socket.
          "hosts allow" = "${cfg.allowedNetwork} 127.0.0.1";
          "hosts deny" = "0.0.0.0/0";

          # SMB3 only; WireGuard already encrypts the link, so skip SMB
          # encryption for speed. No POSIX extensions: clients cannot send
          # chmod/chown through.
          "server min protocol" = "SMB3";
          "smb3 unix extensions" = "no";

          # No printing
          "load printers" = "no";
          printing = "bsd";
          "printcap name" = "/dev/null";
          "disable spoolss" = "yes";
        };
      }
      // mapAttrs (_: shareSettings) cfg.shares;
    };

    networking.firewall.interfaces.${cfg.interface}.allowedTCPPorts = [ 445 ];

    # Keep the Samba password of ${username} in sync with the SOPS secret
    systemd.services.samba-user-sync = {
      description = "Set the Samba password of ${username} from SOPS";
      wantedBy = [ "samba-smbd.service" ];
      before = [ "samba-smbd.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        pw=$(cat ${config.sops.secrets.samba_password.path})
        printf '%s\n%s\n' "$pw" "$pw" | ${samba}/bin/smbpasswd -s -a ${username}
      '';
    };
  };
}
