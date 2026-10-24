{
  config,
  lib,
  pkgs,
  username,
  ...
}:

with lib;

let
  cfg = config.modules.services.syncthing;

  claudeStignore = pkgs.writeText "claude-stignore" ''
    // Managed by NixOS (modules/nixos/services/syncthing).
    /.claude.json
    /.claude.json.*
    /.credentials.json.*
    /*.bak*
    /*.lock
    /.last-cleanup
    /backups
    /cache
    /debug
    /ide
    /paste-cache
    /plugins
    /session-env
    /sessions
    /shell-snapshots
    /skills
    /state
    /statsig
    /telemetry
    /mcp-needs-auth-cache.json
    /policy-limits.json*
    /remote-settings.json*
    /stats-cache.json
  '';
in
{
  options.modules.services.syncthing = {
    enable = mkEnableOption "Syncthing file synchronization";

    user = mkOption {
      type = types.str;
      default = username;
      description = "User to run Syncthing as.";
    };

    group = mkOption {
      type = types.str;
      default = "users";
      description = "Group to run Syncthing as.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/home/${username}/Sync";
      description = "Default directory for synced folders.";
    };

    configDir = mkOption {
      type = types.str;
      default = "/home/${username}/.config/syncthing";
      description = "Configuration directory for Syncthing.";
    };

    openDefaultPorts = mkOption {
      type = types.bool;
      default = true;
      description = "Open firewall ports for Syncthing.";
    };

    guiAddress = mkOption {
      type = types.str;
      default = "127.0.0.1:8384";
      description = "Address to serve the web GUI.";
    };

    settings = mkOption {
      type = types.attrs;
      default = { };
      description = "Extra configuration options for Syncthing (JSON REST API format).";
    };

    overrideDevices = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to delete devices not configured via settings.devices. If false, devices added via web interface persist.";
    };

    overrideFolders = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to delete folders not configured via settings.folders. If false, folders added via web interface persist.";
    };

    guiUser = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Username for Syncthing GUI authentication.";
    };

    guiPasswordFile = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Path to file containing the plaintext password for Syncthing's GUI.";
    };

    claude = {
      devices = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Devices to share the Claude Code config directories with. Empty disables Claude syncing.";
      };

      # One Syncthing folder per account. Every host uses kiwi's layout:
      # plain `claude` is the work account, Personal needs CLAUDE_CONFIG_DIR.
      dirs = mkOption {
        type = types.attrsOf types.str;
        default = {
          claude-carrierx = "/home/${username}/.claude";
          claude-personal = "/home/${username}/.claude-personal";
        };
        description = "Syncthing folder id -> local CLAUDE_CONFIG_DIR for each synced Claude account.";
      };
    };
  };

  config = mkIf cfg.enable {
    # .stignore is never synced, so every host writes its own. Credentials,
    # settings, memory and transcripts sync; per-machine runtime state and the
    # home-manager managed skills/plugins stay local.
    system.activationScripts.syncthing-claude-stignore = mkIf (cfg.claude.devices != [ ]) (
      concatMapStrings (path: ''
        install -d -o ${cfg.user} -g ${cfg.group} ${escapeShellArg path}
        install -m 0644 -o ${cfg.user} -g ${cfg.group} ${claudeStignore} ${escapeShellArg "${path}/.stignore"}
      '') (attrValues cfg.claude.dirs)
    );

    services.syncthing = {
      enable = true;
      user = cfg.user;
      group = cfg.group;
      dataDir = cfg.dataDir;
      configDir = cfg.configDir;
      openDefaultPorts = cfg.openDefaultPorts;
      guiAddress = cfg.guiAddress;
      overrideDevices = cfg.overrideDevices;
      overrideFolders = cfg.overrideFolders;
      inherit (cfg) guiPasswordFile;

      # Only apply declarative settings if explicitly configured
      # This allows users to manage config through the web GUI
      settings = mkIf (cfg.settings != { } || cfg.guiUser != null) (mkMerge [
        {
          gui = {
            address = cfg.guiAddress;
          }
          // optionalAttrs (cfg.guiUser != null) {
            user = cfg.guiUser;
          };
        }
        cfg.settings
        (mkIf (cfg.claude.devices != [ ]) {
          folders = mapAttrs (id: path: {
            inherit id path;
            label = "Claude (${removePrefix "claude-" id})";
            devices = cfg.claude.devices;
          }) cfg.claude.dirs;
        })
      ]);
    };

    # Ensure the user has access to Syncthing data
    systemd.services.syncthing.serviceConfig = {
      UMask = "0027";
      WorkingDirectory = cfg.dataDir;
    };

    # Create data directory for syncthing
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 ${cfg.user} ${cfg.group} -"
    ];
  };
}
