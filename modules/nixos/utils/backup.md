# Container Backup Utilities

This module provides reusable backup functionality for container services. It includes helper functions to create backup services, timers, and directory structures for any container.

## Overview

The backup utilities provide a standardized way to add backup functionality to container services with the following features:

- **Multiple destination paths**: Backup to multiple locations simultaneously
- **Configurable formats**: Support for tar.gz, tar.xz, tar.bz2, and zip
- **Retention policies**: Automatic cleanup of old backups
- **Service management**: Safe stop/start of services during backup
- **Error handling**: Robust error handling and logging

## Helper Functions

### `mkBackupService`

Creates a systemd service for backing up container data.

**Parameters:**

- `name`: Container name (used for service and file naming)
- `serviceName`: Systemd service name to stop/start during backup
- `dataPaths`: List of directories to backup
- `user`: User to own the backup files
- `group`: Group to own the backup files
- `backupConfig`: Backup configuration object

**Example:**

```nix
services.myapp-backup = mkIf cfg.backup.enable (
  mkBackupService {
    name = "myapp";
    serviceName = "docker-myapp.service";
    dataPaths = [
      "/var/lib/myapp/config"
      "/var/lib/myapp/data"
    ];
    user = cfg.user;
    group = cfg.group;
    backupConfig = cfg.backup;
  }
);
```

### `mkBackupTimer`

Creates a systemd timer for scheduling backups.

**Parameters:**

- `name`: Container name (used for timer naming)
- `backupConfig`: Backup configuration object

**Example:**

```nix
systemd.timers.myapp-backup = mkIf cfg.backup.enable (
  mkBackupTimer {
    name = "myapp";
    backupConfig = cfg.backup;
  }
);
```

### `mkBackupDirectories`

Creates systemd tmpfiles rules for backup directories.

**Parameters:**

- `backupConfig`: Backup configuration object
- `user`: User to own the directories
- `group`: Group to own the directories

**Example:**

```nix
systemd.tmpfiles.rules = [
  # ... other rules ...
] ++ mkBackupDirectories {
  backupConfig = cfg.backup;
  user = cfg.user;
  group = cfg.group;
};
```

## Backup Configuration

The backup configuration object should have the following structure:

```nix
backup = {
  enable = true;
  paths = [ "/var/backups/myapp" "/mnt/backup/myapp" ];
  schedule = "0 2 * * *"; # Daily at 2 AM
  format = "tar.gz";
  maxRetentionDays = 30; # Delete backups older than 30 days
retentionSnapshots = 7; # Keep 7 snapshots
};
```

**Options:**

- `enable`: Enable/disable automatic backups
- `paths`: List of backup destination directories
- `schedule`: Cron schedule for backups
- `format`: Archive format (tar.gz, tar.xz, tar.bz2, zip)
- `maxRetentionDays`: Maximum age of backup files in days (0 = no age limit)
- `retentionSnapshots`: Number of backup snapshots to keep (0 = keep all)

## Complete Example

Here's how to add backup functionality to a container module:

```nix
{ config, lib, pkgs, mkBackupService, mkBackupTimer, mkBackupDirectories, ... }:

with lib;

let
  cfg = config.modules.services.virtualization.myapp;
in {
  options.modules.services.virtualization.myapp = {
    enable = mkEnableOption "MyApp container";

    # ... other options ...

    backup = {
      enable = mkEnableOption "MyApp backup service";
      paths = mkOption {
        type = types.listOf types.str;
        default = [ "/var/backups/myapp" ];
        description = "List of backup destination directories";
      };
      schedule = mkOption {
        type = types.str;
        default = "0 0 * * *";
        description = "Cron schedule for backup";
      };
      format = mkOption {
        type = types.enum [ "tar.gz" "tar.xz" "tar.bz2" "zip" ];
        default = "tar.gz";
        description = "Backup archive format";
      };
      maxRetentionDays = mkOption {
        type = types.int;
        default = 0;
        description = "Maximum age of backup files in days (0 = no age limit)";
      };

      retentionSnapshots = mkOption {
        type = types.int;
        default = 7;
        description = "Number of backup snapshots to keep (0 = keep all)";
      };
    };
  };

  config = mkIf cfg.enable {
    # Create backup directories
    systemd.tmpfiles.rules = [
      # ... other rules ...
    ] ++ mkBackupDirectories {
      backupConfig = cfg.backup;
      user = cfg.user;
      group = cfg.group;
    };

    # Create backup service
    services.myapp-backup = mkIf cfg.backup.enable (
      mkBackupService {
        name = "myapp";
        serviceName = "docker-myapp.service";
        dataPaths = [
          "/var/lib/myapp/config"
          "/var/lib/myapp/data"
        ];
        user = cfg.user;
        group = cfg.group;
        backupConfig = cfg.backup;
      }
    );

    # Create backup timer
    systemd.timers.myapp-backup = mkIf cfg.backup.enable (
      mkBackupTimer {
        name = "myapp";
        backupConfig = cfg.backup;
      }
    );
  };
}
```

## Usage in Host Configuration

```nix
{
  modules.services.virtualization.myapp = {
    enable = true;

    # ... other configuration ...

    backup = {
      enable = true;
      paths = [
        "/var/backups/myapp"
        "/mnt/backup/myapp"
        "/mnt/cloud/myapp"
      ];
      schedule = "0 2 * * *"; # Daily at 2 AM
      format = "tar.xz";
      maxRetentionDays = 30; # Delete backups older than 30 days
retentionSnapshots = 10; # Keep 10 snapshots
    };
  };
}
```

## Backup Process

1. **Stop Service**: Safely stops the container service
2. **Create Backup**: Creates compressed archive of specified directories
3. **Distribute**: Copies backup to all configured destination paths
4. **Cleanup**: Removes old backups based on retention policy for each destination
5. **Restart Service**: Restarts the container service
6. **Cleanup**: Removes temporary backup file

## Features

- **Multiple Destinations**: Backup to multiple locations simultaneously
- **Flexible Scheduling**: Configurable cron schedules
- **Format Options**: Support for various compression formats
- **Retention Policies**: Automatic cleanup of old backups
- **Error Handling**: Robust error handling and logging
- **Service Safety**: Safe stop/start of services during backup
- **Ownership Management**: Proper file ownership and permissions
