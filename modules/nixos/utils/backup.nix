{ config, lib, pkgs, ... }:

with lib;

let
  # Helper function to create backup service for any container
  mkBackupService = { name, serviceName, dataPaths, user, group, backupConfig }:
    let cfg = backupConfig;
    in {
      enable = true;
      description = "${name} backup service";
      # Run as root to have privileges to stop/start systemd services
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        Group = "root";
        Restart = "no";
      };
      path =
        [ pkgs.coreutils pkgs.gzip pkgs.xz pkgs.bzip2 pkgs.zip pkgs.gnutar ];
      script = ''
        #!/bin/bash
        set -euo pipefail

        # Configuration
        BACKUP_PATHS=(${toString cfg.paths})
        SERVICE_NAME="${serviceName}"
        DATA_PATHS=(${toString dataPaths})
        USER="${user}"
        GROUP="${group}"
        DATE=$(date +%Y%m%d_%H%M%S)

        # Create backup directories if they don't exist
        for backup_path in "''${BACKUP_PATHS[@]}"; do
          mkdir -p "$backup_path"
        done

        # Determine archive format and extension
        case "${cfg.format}" in
          "tar.gz")
            ARCHIVE_EXT="tar.gz"
            COMPRESS_CMD="gzip"
            ;;
          "tar.xz")
            ARCHIVE_EXT="tar.xz"
            COMPRESS_CMD="xz"
            ;;
          "tar.bz2")
            ARCHIVE_EXT="tar.bz2"
            COMPRESS_CMD="bzip2"
            ;;
          "zip")
            ARCHIVE_EXT="zip"
            COMPRESS_CMD="zip"
            ;;
        esac

        BACKUP_FILENAME="${name}_backup_$DATE.$ARCHIVE_EXT"

        echo "[$(date)] Starting ${name} backup..."

        # Stop service to prevent corruption
        echo "[$(date)] Stopping ${name} service..."
        if systemctl is-active --quiet "$SERVICE_NAME"; then
          systemctl stop "$SERVICE_NAME"
          echo "[$(date)] ${name} service stopped"
        else
          echo "[$(date)] ${name} service was not running"
        fi

        # Wait a moment for any pending writes
        sleep 5

        # Create backup
        echo "[$(date)] Creating backup..."

        # Build list of directories to backup
        BACKUP_DIRS=""
        for data_path in "''${DATA_PATHS[@]}"; do
          if [ -d "$data_path" ]; then
            BACKUP_DIRS="$BACKUP_DIRS $data_path"
          fi
        done

        if [ -z "$BACKUP_DIRS" ]; then
          echo "[$(date)] Error: No directories to backup found"
          exit 1
        fi

        # Create temporary backup file
        TEMP_BACKUP="/tmp/${name}_backup_$DATE.$ARCHIVE_EXT"

        # Create archive based on format
        if [ "${cfg.format}" = "zip" ]; then
          # For zip, we need to change to the parent directory and archive subdirectories
          PARENT_DIR=$(dirname "''${DATA_PATHS[0]}")
          cd "$PARENT_DIR"
          zip -r "$TEMP_BACKUP" $(basename $BACKUP_DIRS) > /dev/null 2>&1
        else
          tar -cf - $BACKUP_DIRS | $COMPRESS_CMD > "$TEMP_BACKUP"
        fi

        if [ $? -eq 0 ]; then
          echo "[$(date)] Backup created successfully: $TEMP_BACKUP"
          
          # Copy backup to all destination paths
          for backup_path in "''${BACKUP_PATHS[@]}"; do
            echo "[$(date)] Copying backup to: $backup_path"
            cp "$TEMP_BACKUP" "$backup_path/$BACKUP_FILENAME"
            
            if [ $? -eq 0 ]; then
              # Set proper ownership
              chown $USER:$GROUP "$backup_path/$BACKUP_FILENAME"
              echo "[$(date)] Backup copied successfully to: $backup_path/$BACKUP_FILENAME"
              
              # Cleanup old backups based on retention settings
              cd "$backup_path"
              
              # Cleanup by age (maxRetentionDays)
              if [ ${toString cfg.maxRetentionDays} -gt 0 ]; then
                echo "[$(date)] Cleaning up backups older than ${
                  toString cfg.maxRetentionDays
                } days in $backup_path..."
                find . -name "${name}_backup_*.$ARCHIVE_EXT" -type f -mtime +${
                  toString cfg.maxRetentionDays
                } -delete
              fi
              
              # Cleanup by snapshots (retentionSnapshots)
              if [ ${toString cfg.retentionSnapshots} -gt 0 ]; then
                echo "[$(date)] Cleaning up old snapshots in $backup_path (keeping ${
                  toString cfg.retentionSnapshots
                } snapshots)..."
                ls -t ${name}_backup_*.$ARCHIVE_EXT 2>/dev/null | tail -n +$(( ${
                  toString cfg.retentionSnapshots
                } + 1 )) | xargs -r rm -f
              fi
            else
              echo "[$(date)] Error: Failed to copy backup to: $backup_path"
            fi
          done
          
          # Clean up temporary backup file
          rm -f "$TEMP_BACKUP"
          echo "[$(date)] Temporary backup file cleaned up"
        else
          echo "[$(date)] Error: Backup creation failed"
          exit 1
        fi

        # Restart service
        echo "[$(date)] Restarting ${name} service..."
        systemctl start "$SERVICE_NAME"

        if systemctl is-active --quiet "$SERVICE_NAME"; then
          echo "[$(date)] ${name} service restarted successfully"
        else
          echo "[$(date)] Warning: ${name} service may not have started properly"
        fi

        echo "[$(date)] Backup process completed"
      '';
    };

  # Helper function to convert cron schedule to systemd calendar format
  cronToSystemdCalendar = cronSchedule:
    let
      parts = builtins.split " " cronSchedule;
      minute = builtins.elemAt parts 0;
      hour = builtins.elemAt parts 2;
      day = builtins.elemAt parts 4;
      month = builtins.elemAt parts 6;
      weekday = builtins.elemAt parts 8;
    in if weekday == "*" then
    # Daily schedule
      "*-*-* ${hour}:${minute}:00"
    else if weekday == "0" then
    # Weekly schedule (Sunday)
      "Sun *-*-* ${hour}:${minute}:00"
    else if weekday == "1" then
    # Weekly schedule (Monday)
      "Mon *-*-* ${hour}:${minute}:00"
    else if weekday == "2" then
    # Weekly schedule (Tuesday)
      "Tue *-*-* ${hour}:${minute}:00"
    else if weekday == "3" then
    # Weekly schedule (Wednesday)
      "Wed *-*-* ${hour}:${minute}:00"
    else if weekday == "4" then
    # Weekly schedule (Thursday)
      "Thu *-*-* ${hour}:${minute}:00"
    else if weekday == "5" then
    # Weekly schedule (Friday)
      "Fri *-*-* ${hour}:${minute}:00"
    else if weekday == "6" then
    # Weekly schedule (Saturday)
      "Sat *-*-* ${hour}:${minute}:00"
    else
    # Fallback to daily
      "*-*-* ${hour}:${minute}:00";

  # Helper function to create backup timer for any container
  mkBackupTimer = { name, backupConfig }:
    let cfg = backupConfig;
    in {
      enable = true;
      description = "${name} backup timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cronToSystemdCalendar cfg.schedule;
        Persistent = true;
        RandomizedDelaySec = 300; # Random delay up to 5 minutes
      };
    };

  # Helper function to create backup directories for any container
  mkBackupDirectories = { backupConfig, user, group }:
    let cfg = backupConfig;
    in if cfg.enable then
      (map (path: "d ${path} 0755 ${user} ${group} -") cfg.paths)
    else
      [ ];

in {
  # Export the helper functions
  _module.args = {
    mkBackupService = mkBackupService;
    mkBackupTimer = mkBackupTimer;
    mkBackupDirectories = mkBackupDirectories;
  };
}
