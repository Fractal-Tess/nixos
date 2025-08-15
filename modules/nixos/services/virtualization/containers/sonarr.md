# Sonarr Container Module

## Overview

Sonarr is a powerful TV show management tool that automates the process of finding, downloading, and organizing TV series. It integrates with torrent clients, Usenet clients, and media management tools to provide a complete automated TV show experience.

## Features

- **Automated TV Show Management**: Automatically finds and downloads new episodes
- **Quality Profiles**: Configurable quality preferences and upgrade paths
- **Multiple Download Clients**: Support for qBittorrent, Transmission, SABnzbd, and more
- **Indexer Integration**: Works with Jackett for unified torrent searching
- **Media Organization**: Automatic file renaming and organization
- **Web Interface**: Full-featured web UI for configuration and monitoring
- **Backup Support**: Automated backup and restore functionality
- **Flexible Mounting**: Configurable bind mounts for data persistence

## Configuration

### Basic Configuration

```nix
modules.services.virtualization.containers.sonarr = {
  enable = true;

  # User/Group configuration
  uid = 1006;
  gid = 1006;

  # Port configuration
  webPort = 8989;

  # Firewall
  openFirewallPorts = true;
};
```

### Advanced Configuration

```nix
modules.services.virtualization.containers.sonarr = {
  enable = true;

  # Custom image
  image = "linuxserver/sonarr";
  imageTag = "latest";

  # User/Group
  uid = 1006;
  gid = 1006;

  # Custom port
  webPort = 8989;

  # Custom bind mounts
  bindMounts = [
    {
      hostPath = "/var/lib/sonarr/config";
      containerPath = "/config";
      readOnly = false;
      backup = true;
    }
    {
      hostPath = "/media/tv";
      containerPath = "/media/tv";
      readOnly = true;
      backup = false;
    }
    {
      hostPath = "/var/lib/sonarr/downloads";
      containerPath = "/downloads";
      readOnly = false;
      backup = false;
    }
    {
      hostPath = "/var/lib/sonarr/tv";
      containerPath = "/tv";
      readOnly = false;
      backup = false;
    }
  ];

  # Backup configuration
  backup = {
    enable = true;
    schedule = "0 0 * * *"; # Daily at midnight
    paths = [ "/var/backups/sonarr" "/mnt/backup/sonarr" ];
    format = "tar.gz";
    retentionSnapshots = 10;
    maxRetentionDays = 30;
  };

  # Firewall
  openFirewallPorts = true;
};
```

## Default Bind Mounts

The module provides sensible defaults for bind mounts:

- **`/var/lib/sonarr/config`** → `/config` (read-write, backed up)
- **`/var/lib/sonarr/downloads`** → `/downloads` (read-write, not backed up)
- **`/var/lib/sonarr/tv`** → `/tv` (read-write, not backed up)

## Port Configuration

- **Web Port**: 8989 (configurable via `webPort` option)

## Environment Variables

- **`PUID`**: User ID for file permissions
- **`PGID`**: Group ID for file permissions
- **`TZ`**: System timezone

## Backup and Restore

The module includes comprehensive backup and restore functionality:

### Backup Features

- **Automated Backups**: Daily backups at configurable times
- **Multiple Destinations**: Support for multiple backup locations
- **Format Options**: tar.gz, tar.xz, tar.bz2, or zip
- **Retention Policies**: Configurable retention periods and snapshot counts
- **Selective Backup**: Only backup data marked for backup in bind mounts

### Restore Features

- **Manual Restore**: Restore script for manual data recovery
- **User Permissions**: Maintains proper file ownership during restore
- **Flexible Restore**: Restore to any configured backup location

## Integration

### Download Clients

Sonarr integrates with various download clients:

- **qBittorrent**: Torrent client (recommended)
- **Transmission**: Lightweight torrent client
- **SABnzbd**: Usenet client
- **NZBGet**: Alternative Usenet client

### Indexers

Sonarr works with indexers for finding content:

- **Jackett**: Torrent indexer proxy (recommended)
- **Prowlarr**: Alternative indexer manager
- **Direct Indexers**: Individual torrent and Usenet indexers

### Media Management

Sonarr integrates with media management tools:

- **Jellyfin**: Media server
- **Plex**: Media server
- **Emby**: Media server

## Configuration Workflow

### Initial Setup

1. **Access Web Interface**: Navigate to `http://your-server:8989`
2. **Add Download Client**: Configure qBittorrent or other download client
3. **Add Indexers**: Configure Jackett or direct indexers
4. **Set Root Folders**: Configure where TV shows should be stored
5. **Add TV Shows**: Search and add TV shows to monitor

### Download Client Configuration

```bash
# Example qBittorrent configuration
Host: localhost
Port: 8080
Username: admin
Password: your-password
Category: tv
```

### Indexer Configuration

```bash
# Example Jackett configuration
URL: http://localhost:9117
API Key: your-jackett-api-key
```

## Security Considerations

- **Network Mode**: Uses host networking for better discovery
- **User Isolation**: Runs as dedicated system user
- **File Permissions**: Proper ownership and permissions for mounted volumes
- **Firewall**: Optional port opening for external access

## Troubleshooting

### Common Issues

1. **Permission Errors**: Ensure UID/GID match your system user
2. **Port Conflicts**: Check if port 8989 is already in use
3. **Mount Failures**: Verify host paths exist and have correct permissions
4. **Backup Failures**: Check backup directory permissions and disk space
5. **Download Client Connection**: Verify download client is accessible

### Logs

View container logs:

```bash
journalctl -u docker-sonarr.service
```

### Manual Container Management

Start/stop the container:

```bash
systemctl start docker-sonarr.service
systemctl stop docker-sonarr.service
```

## Examples

### Minimal Configuration

```nix
modules.services.virtualization.containers.sonarr = {
  enable = true;
  uid = 1006;
  gid = 1006;
};
```

### Production Configuration

```nix
modules.services.virtualization.containers.sonarr = {
  enable = true;

  uid = 1006;
  gid = 1006;

  webPort = 8989;

  bindMounts = [
    {
      hostPath = "/var/lib/sonarr/config";
      containerPath = "/config";
      readOnly = false;
      backup = true;
    }
    {
      hostPath = "/mnt/vault/tv";
      containerPath = "/media/tv";
      readOnly = true;
      backup = false;
    }
    {
      hostPath = "/var/lib/sonarr/downloads";
      containerPath = "/downloads";
      readOnly = false;
      backup = false;
    }
  ];

  backup = {
    enable = true;
    schedule = "0 2 * * *"; # Daily at 2AM
    paths = [ "/var/backups/sonarr" "/mnt/backup/sonarr" ];
    format = "tar.xz";
    retentionSnapshots = 14;
    maxRetentionDays = 60;
  };

  openFirewallPorts = true;
};
```

## References

- [Sonarr Official Website](https://sonarr.tv/)
- [Docker Hub Image](https://hub.docker.com/r/linuxserver/sonarr/)
- [Sonarr Documentation](https://wiki.servarr.com/sonarr)
- [Sonarr GitHub Repository](https://github.com/Sonarr/Sonarr)
