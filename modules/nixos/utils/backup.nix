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

  # Helper function to create restore script for any container
  mkRestoreScript = { name, dataPaths, user, group, backupConfig }:
    let cfg = backupConfig;
    in {
      enable = true;
      description = "${name} restore script";
      path = [
        pkgs.coreutils
        pkgs.gzip
        pkgs.xz
        pkgs.bzip2
        pkgs.zip
        pkgs.gnutar
        pkgs.bash
      ];
      script = ''
        #!/bin/bash
        set -euo pipefail

        # Configuration
        BACKUP_PATHS=(${toString cfg.paths})
        DATA_PATHS=(${toString dataPaths})
        USER="${user}"
        GROUP="${group}"
        SERVICE_NAME="docker-${name}.service"

        # Determine archive format and extension
        case "${cfg.format}" in
          "tar.gz")
            ARCHIVE_EXT="tar.gz"
            EXTRACT_CMD="tar -xzf"
            ;;
          "tar.xz")
            ARCHIVE_EXT="tar.xz"
            EXTRACT_CMD="tar -xJf"
            ;;
          "tar.bz2")
            ARCHIVE_EXT="tar.bz2"
            EXTRACT_CMD="tar -xjf"
            ;;
          "zip")
            ARCHIVE_EXT="zip"
            EXTRACT_CMD="unzip -o"
            ;;
        esac

        echo "=== ${name} Restore Script ==="
        echo "This script will help you restore ${name} from a backup."
        echo ""

        # Function to list available backups
        list_backups() {
          echo "Available backups:"
          echo "=================="
          
          local backup_count=0
          local backup_list=()
          
          for backup_path in "''${BACKUP_PATHS[@]}"; do
            if [ -d "$backup_path" ]; then
              echo ""
              echo "Backup location: $backup_path"
              echo "----------------------------------------"
              
              # Find all backup files for this service
              while IFS= read -r -d $'\0' file; do
                if [[ "$file" == *"${name}_backup_"*".$ARCHIVE_EXT" ]]; then
                  backup_count=$((backup_count + 1))
                  backup_list+=("$file")
                  
                  # Extract date from filename
                  local filename=$(basename "$file")
                  local date_part=$(echo "$filename" | sed -n "s/${name}_backup_\\(.*\\)\\.$ARCHIVE_EXT/\\1/p")
                  
                  echo "$backup_count) $filename (Date: $date_part)"
                fi
              done < <(find "$backup_path" -name "${name}_backup_*.$ARCHIVE_EXT" -print0 2>/dev/null | sort -z)
            fi
          done
          
          echo ""
          if [ $backup_count -eq 0 ]; then
            echo "No backups found!"
            return 1
          fi
          
          return 0
        }

        # Function to restore from backup
        restore_backup() {
          local backup_file="$1"
          local temp_dir="/tmp/${name}_restore_$$"
          
          echo ""
          echo "Restoring from: $backup_file"
          echo "=========================="
          
          # Create temporary directory
          mkdir -p "$temp_dir"
          
          # Stop service if running
          echo "Stopping ${name} service..."
          if systemctl is-active --quiet "$SERVICE_NAME"; then
            systemctl stop "$SERVICE_NAME"
            echo "Service stopped."
          else
            echo "Service was not running."
          fi
          
          # Wait a moment
          sleep 3
          
          # Extract backup to temporary directory
          echo "Extracting backup..."
          cd "$temp_dir"
          
          if [ "${cfg.format}" = "zip" ]; then
            $EXTRACT_CMD "$backup_file" > /dev/null 2>&1
          else
            $EXTRACT_CMD "$backup_file" > /dev/null 2>&1
          fi
          
          if [ $? -ne 0 ]; then
            echo "Error: Failed to extract backup file"
            rm -rf "$temp_dir"
            exit 1
          fi
          
          # Restore files to their original locations
          echo "Restoring files..."
          for data_path in "''${DATA_PATHS[@]}"; do
            local dir_name=$(basename "$data_path")
            local restore_path="$temp_dir/$dir_name"
            
            if [ -d "$restore_path" ]; then
              echo "Restoring $data_path..."
              
                             # Create backup of existing directory if it exists
               if [ -d "$data_path" ]; then
                 local backup_name="''${data_path}_backup_\$(date +%Y%m%d_%H%M%S)"
                 echo "Creating backup of existing directory: \$backup_name"
                 cp -r "$data_path" "$backup_name"
               fi
              
              # Remove existing directory and restore
              rm -rf "$data_path"
              cp -r "$restore_path" "$data_path"
              
              # Set proper ownership
              chown -R $USER:$GROUP "$data_path"
              
              echo "Restored: $data_path"
            fi
          done
          
          # Clean up temporary directory
          rm -rf "$temp_dir"
          
          # Start service
          echo "Starting ${name} service..."
          systemctl start "$SERVICE_NAME"
          
          if systemctl is-active --quiet "$SERVICE_NAME"; then
            echo "Service started successfully."
          else
            echo "Warning: Service may not have started properly."
          fi
          
          echo ""
          echo "Restore completed successfully!"
        }

        # Main script logic
        if ! list_backups; then
          exit 1
        fi

        echo "Enter the number of the backup to restore (or 'q' to quit):"
        read -r choice

        if [[ "$choice" == "q" || "$choice" == "Q" ]]; then
          echo "Restore cancelled."
          exit 0
        fi

        if [[ ! "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt $backup_count ]; then
          echo "Invalid choice. Please enter a number between 1 and $backup_count."
          exit 1
        fi

        # Get the selected backup file
        selected_backup="''${backup_list[$((choice - 1))]}"

        # Confirm restore
        echo ""
        echo "You selected: $(basename "$selected_backup")"
        echo "This will overwrite existing ${name} data."
        echo "Are you sure you want to continue? (y/N):"
        read -r confirm

        if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
          restore_backup "$selected_backup"
        else
          echo "Restore cancelled."
          exit 0
        fi
      '';
    };

in {
  # Export the helper functions
  _module.args = {
    mkBackupService = mkBackupService;
    mkBackupTimer = mkBackupTimer;
    mkBackupDirectories = mkBackupDirectories;
    mkRestoreScript = mkRestoreScript;
  };
}
