# qBittorrent Container Module

## Overview

qBittorrent is a popular open-source BitTorrent client that provides a web-based interface for managing torrent downloads. It offers advanced features like bandwidth control, scheduling, and integration with media management tools.

## Features

- **Web Interface**: Full-featured web UI accessible from any device
- **Advanced Controls**: Bandwidth limiting, scheduling, and queue management
- **RSS Support**: Automatic download from RSS feeds
- **Search Integration**: Built-in search functionality for popular torrent sites
- **Mobile App**: Official mobile apps for remote management
- **Backup Support**: Automated backup and restore functionality
- **Flexible Mounting**: Configurable bind mounts for data persistence

## Configuration

### Basic Configuration

```nix
modules.services.virtualization.containers.qbittorrent = {
  enable = true;

  # User/Group configuration
  uid = 1005;
  gid = 1005;

  # Port configuration
  webPort = 8080;

  # Firewall
  openFirewallPorts = true;
};
```

### Advanced Configuration

```nix
modules.services.virtualization.containers.qbittorrent = {
  enable = true;

  # Custom image
  image = "linuxserver/qbittorrent";
  imageTag = "latest";

  # User/Group
  uid = 1005;
  gid = 1005;

  # Custom port
  webPort = 8081;

  # Custom bind mounts
  bindMounts = [
    {
      hostPath = "/var/lib/qbittorrent/config";
      containerPath = "/config";
      readOnly = false;
      backup = true;
    }
    {
      hostPath = "/media/torrents";
      containerPath = "/media/torrents";
      readOnly = true;
      backup = false;
    }
    {
      hostPath = "/var/lib/qbittorrent/downloads";
      containerPath = "/downloads";
      readOnly = false;
      backup = false;
    }
    {
      hostPath = "/var/lib/qbittorrent/torrents";
      containerPath = "/torrents";
      readOnly = false;
      backup = false;
    }
  ];

  # Backup configuration
  backup = {
    enable = true;
    schedule = "0 23 * * *"; # Daily at 11PM
    paths = [ "/var/backups/qbittorrent" "/mnt/backup/qbittorrent" ];
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

- **`/var/lib/qbittorrent/config`** → `/config` (read-write, backed up)
- **`/var/lib/qbittorrent/downloads`** → `/downloads` (read-write, not backed up)
- **`/var/lib/qbittorrent/torrents`** → `/torrents` (read-write, not backed up)

## Port Configuration

- **Web Port**: 8080 (configurable via `webPort` option)

## Environment Variables

- **`PUID`**: User ID for file permissions
- **`PGID`**: Group ID for file permissions
- **`TZ`**: System timezone
- **`WEBUI_PORT`**: Web interface port (internal)

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

### Media Management Tools

qBittorrent integrates with popular media management applications:

- **Sonarr**: TV show management
- **Radarr**: Movie management
- **Lidarr**: Music management
- **Readarr**: Book management

### Configuration

1. Configure qBittorrent categories in the web interface
2. Set up your media management tool to use qBittorrent
3. Configure download paths and categories
4. Set up RSS feeds for automatic downloads

## Security Considerations

- **Network Mode**: Uses host networking for better discovery
- **User Isolation**: Runs as dedicated system user
- **File Permissions**: Proper ownership and permissions for mounted volumes
- **Firewall**: Optional port opening for external access

## Troubleshooting

### Common Issues

1. **Permission Errors**: Ensure UID/GID match your system user
2. **Port Conflicts**: Check if port 8080 is already in use
3. **Mount Failures**: Verify host paths exist and have correct permissions
4. **Backup Failures**: Check backup directory permissions and disk space

### Logs

View container logs:

```bash
journalctl -u docker-qbittorrent.service
```

### Manual Container Management

Start/stop the container:

```bash
systemctl start docker-qbittorrent.service
systemctl stop docker-qbittorrent.service
```

## Examples

### Minimal Configuration

```nix
modules.services.virtualization.containers.qbittorrent = {
  enable = true;
  uid = 1005;
  gid = 1005;
};
```

### Production Configuration

```nix
modules.services.virtualization.containers.qbittorrent = {
  enable = true;

  uid = 1005;
  gid = 1005;

  webPort = 8080;

  bindMounts = [
    {
      hostPath = "/var/lib/qbittorrent/config";
      containerPath = "/config";
      readOnly = false;
      backup = true;
    }
    {
      hostPath = "/mnt/torrents";
      containerPath = "/media/torrents";
      readOnly = true;
      backup = false;
    }
    {
      hostPath = "/var/lib/qbittorrent/downloads";
      containerPath = "/downloads";
      readOnly = false;
      backup = false;
    }
  ];

  backup = {
    enable = true;
    schedule = "0 1 * * *"; # Daily at 1AM
    paths = [ "/var/backups/qbittorrent" "/mnt/backup/qbittorrent" ];
    format = "tar.xz";
    retentionSnapshots = 14;
    maxRetentionDays = 60;
  };

  openFirewallPorts = true;
};
```

## References

- [qBittorrent Official Website](https://www.qbittorrent.org/)
- [Docker Hub Image](https://hub.docker.com/r/linuxserver/qbittorrent/)
- [qBittorrent Documentation](https://github.com/qbittorrent/qBittorrent/wiki)
