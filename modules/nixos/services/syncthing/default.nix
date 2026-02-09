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
  };

  config = mkIf cfg.enable {
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

      # Only apply declarative settings if explicitly configured
      # This allows users to manage config through the web GUI
      settings = mkIf (cfg.settings != { }) (mkMerge [
        {
          gui = {
            address = cfg.guiAddress;
          };
        }
        cfg.settings
      ]);
    };

    # Ensure the user has access to Syncthing data
    systemd.services.syncthing.serviceConfig = {
      UMask = "0027";
    };
  };
}
