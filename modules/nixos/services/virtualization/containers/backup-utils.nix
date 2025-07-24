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

  # Helper function to create backup timer for any container
  mkBackupTimer = { name, backupConfig }:
    let cfg = backupConfig;
    in {
      enable = true;
      description = "${name} backup timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily"; # Run daily at midnight
        Persistent = true;
        RandomizedDelaySec = 300; # Random delay up to 5 minutes
      };
    };

  # Helper function to create boot-time backup service for any container
  mkBootBackupService =
    { name, serviceName, dataPaths, user, group, backupConfig }:
    let cfg = backupConfig;
    in {
      enable = true;
      description = "${name} boot-time backup check service";
      # Run after network is up but before the main service starts
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      # Run as root to have privileges to stop/start systemd services
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        Group = "root";
        Restart = "no";
        RemainAfterExit = true;
      };
      path = [
        pkgs.coreutils
        pkgs.gzip
        pkgs.xz
        pkgs.bzip2
        pkgs.zip
        pkgs.gnutar
        pkgs.findutils
      ];
      script = ''
        #!/bin/bash
        set -euo pipefail

        # Configuration
        BACKUP_PATHS=(${toString cfg.paths})
        SERVICE_NAME="${serviceName}"
        DATA_PATHS=(${toString dataPaths})
        USER="${user}"
        GROUP="${group}"
        SCHEDULE="${cfg.schedule}"
        DATE=$(date +%Y%m%d_%H%M%S)

        # Function to parse cron schedule and get next run time
        get_next_run_time() {
          local cron_schedule="$1"
          local current_time="$2"
          
          # Parse cron schedule (minute hour day month weekday)
          # For now, we'll handle common cases: daily, weekly, monthly
          case "$cron_schedule" in
            "0 0 * * *"|"0 2 * * *"|"0 3 * * *"|"0 4 * * *"|"0 5 * * *"|"0 6 * * *"|"0 7 * * *"|"0 8 * * *"|"0 9 * * *"|"0 10 * * *"|"0 11 * * *"|"0 12 * * *"|"0 13 * * *"|"0 14 * * *"|"0 15 * * *"|"0 16 * * *"|"0 17 * * *"|"0 18 * * *"|"0 19 * * *"|"0 20 * * *"|"0 21 * * *"|"0 22 * * *"|"0 23 * * *")
              # Daily backup - check if we missed yesterday's backup
              local yesterday=$(date -d "yesterday" +%s)
              echo $yesterday
              ;;
            "0 0 * * 0"|"0 2 * * 0"|"0 3 * * 0"|"0 4 * * 0"|"0 5 * * 0"|"0 6 * * 0"|"0 7 * * 0"|"0 8 * * 0"|"0 9 * * 0"|"0 10 * * 0"|"0 11 * * 0"|"0 12 * * 0"|"0 13 * * 0"|"0 14 * * 0"|"0 15 * * 0"|"0 16 * * 0"|"0 17 * * 0"|"0 18 * * 0"|"0 19 * * 0"|"0 20 * * 0"|"0 21 * * 0"|"0 22 * * 0"|"0 23 * * 0")
              # Weekly backup (Sunday) - check if we missed last Sunday's backup
              local last_sunday=$(date -d "last sunday" +%s)
              echo $last_sunday
              ;;
            "0 0 1 * *"|"0 2 1 * *"|"0 3 1 * *"|"0 4 1 * *"|"0 5 1 * *"|"0 6 1 * *"|"0 7 1 * *"|"0 8 1 * *"|"0 9 1 * *"|"0 10 1 * *"|"0 11 1 * *"|"0 12 1 * *"|"0 13 1 * *"|"0 14 1 * *"|"0 15 1 * *"|"0 16 1 * *"|"0 17 1 * *"|"0 18 1 * *"|"0 19 1 * *"|"0 20 1 * *"|"0 21 1 * *"|"0 22 1 * *"|"0 23 1 * *")
              # Monthly backup (1st of month) - check if we missed last month's backup
              local last_month=$(date -d "last month" +%s)
              echo $last_month
              ;;
            *)
              # For other schedules, use a conservative approach: if backup is older than 24 hours, create one
              local yesterday=$(date -d "yesterday" +%s)
              echo $yesterday
              ;;
          esac
        }

        # Check if we need to create a backup on boot
        NEED_BACKUP=false

        # Check each backup path for the most recent backup
        for backup_path in "''${BACKUP_PATHS[@]}"; do
          if [ -d "$backup_path" ]; then
            # Find the most recent backup file
            LATEST_BACKUP=$(find "$backup_path" -name "${name}_backup_*" -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
            
            if [ -n "$LATEST_BACKUP" ]; then
              # Get the modification time of the latest backup
              BACKUP_TIME=$(stat -c %Y "$LATEST_BACKUP")
              CURRENT_TIME=$(date +%s)
              
              # Get the expected last backup time based on schedule
              EXPECTED_LAST_BACKUP=$(get_next_run_time "$SCHEDULE" "$CURRENT_TIME")
              
              # If the last backup is older than the expected last backup time, we missed a backup
              if [ $BACKUP_TIME -lt $EXPECTED_LAST_BACKUP ]; then
                NEED_BACKUP=true
                echo "[$(date)] Last backup is older than expected schedule, creating boot-time backup"
                echo "[$(date)] Last backup: $(date -d @$BACKUP_TIME)"
                echo "[$(date)] Expected after: $(date -d @$EXPECTED_LAST_BACKUP)"
                break
              else
                echo "[$(date)] Last backup is recent enough, no boot-time backup needed"
                echo "[$(date)] Last backup: $(date -d @$BACKUP_TIME)"
                echo "[$(date)] Expected after: $(date -d @$EXPECTED_LAST_BACKUP)"
              fi
            else
              # No backup found, we need to create one
              NEED_BACKUP=true
              echo "[$(date)] No previous backup found, creating initial backup"
              break
            fi
          fi
        done

        if [ "$NEED_BACKUP" = true ]; then
          echo "[$(date)] Starting boot-time backup for ${name}..."
          
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

          BACKUP_FILENAME="${name}_backup_boot_$DATE.$ARCHIVE_EXT"

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
          echo "[$(date)] Creating boot-time backup..."

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
          TEMP_BACKUP="/tmp/${name}_backup_boot_$DATE.$ARCHIVE_EXT"

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
            echo "[$(date)] Boot-time backup created successfully: $TEMP_BACKUP"
            
            # Copy backup to all destination paths
            for backup_path in "''${BACKUP_PATHS[@]}"; do
              echo "[$(date)] Copying boot-time backup to: $backup_path"
              cp "$TEMP_BACKUP" "$backup_path/$BACKUP_FILENAME"
              
              if [ $? -eq 0 ]; then
                # Set proper ownership
                chown $USER:$GROUP "$backup_path/$BACKUP_FILENAME"
                echo "[$(date)] Boot-time backup copied successfully to: $backup_path/$BACKUP_FILENAME"
                
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
                echo "[$(date)] Error: Failed to copy boot-time backup to: $backup_path"
              fi
            done
            
            # Clean up temporary backup file
            rm -f "$TEMP_BACKUP"
            echo "[$(date)] Temporary boot-time backup file cleaned up"
          else
            echo "[$(date)] Error: Boot-time backup creation failed"
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

          echo "[$(date)] Boot-time backup process completed"
        else
          echo "[$(date)] No boot-time backup needed for ${name}"
        fi
      '';
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
    mkBootBackupService = mkBootBackupService;
    mkBackupDirectories = mkBackupDirectories;
  };
}
