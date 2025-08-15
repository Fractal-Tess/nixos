# Jackett Container Module

## Overview

Jackett is a proxy server that provides a unified API for various torrent trackers. It allows you to search across multiple torrent sites from a single interface and integrates with applications like Sonarr, Radarr, and other media management tools.

## Features

- **Unified Search**: Search across multiple torrent trackers simultaneously
- **API Integration**: RESTful API for integration with media management tools
- **Web Interface**: User-friendly web UI for configuration and monitoring
- **Automatic Updates**: Built-in updater for Jackett and indexer configurations
- **Backup Support**: Automated backup and restore functionality
- **Flexible Mounting**: Configurable bind mounts for data persistence

## Configuration

### Basic Configuration

```nix
modules.services.virtualization.containers.jackett = {
  enable = true;

  # User/Group configuration
  uid = 1004;
  gid = 1004;

  # Port configuration
  httpPort = 9117;

  # Firewall
  openFirewallPorts = true;
};
```

### Advanced Configuration

```nix
modules.services.virtualization.containers.jackett = {
  enable = true;

  # Custom image
  image = "linuxserver/jackett";
  imageTag = "latest";

  # User/Group
  uid = 1004;
  gid = 1004;

  # Custom port
  httpPort = 9118;

  # Custom bind mounts
  bindMounts = [
    {
      hostPath = "/var/lib/jackett/config";
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
      hostPath = "/var/lib/jackett/downloads";
      containerPath = "/downloads";
      readOnly = false;
      backup = false;
    }
  ];

  # Backup configuration
  backup = {
    enable = true;
    schedule = "0 22 * * *"; # Daily at 10PM
    paths = [ "/var/backups/jackett" "/mnt/backup/jackett" ];
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

- **`/var/lib/jackett/config`** → `/config` (read-write, backed up)
- **`/var/lib/jackett/downloads`** → `/downloads` (read-write, not backed up)

## Port Configuration

- **HTTP Port**: 9117 (configurable via `httpPort` option)

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

### Media Management Tools

Jackett integrates with popular media management applications:

- **Sonarr**: TV show management
- **Radarr**: Movie management
- **Lidarr**: Music management
- **Readarr**: Book management

### Configuration

1. Add Jackett indexers in the web interface
2. Configure your media management tool to use Jackett's API
3. Set the Jackett URL: `http://your-server:9117`
4. Add the API key from Jackett's configuration

## Security Considerations

- **Network Mode**: Uses host networking for better discovery
- **User Isolation**: Runs as dedicated system user
- **File Permissions**: Proper ownership and permissions for mounted volumes
- **Firewall**: Optional port opening for external access

## Troubleshooting

### Common Issues

1. **Permission Errors**: Ensure UID/GID match your system user
2. **Port Conflicts**: Check if port 9117 is already in use
3. **Mount Failures**: Verify host paths exist and have correct permissions
4. **Backup Failures**: Check backup directory permissions and disk space

### Logs

View container logs:

```bash
journalctl -u docker-jackett.service
```

### Manual Container Management

Start/stop the container:

```bash
systemctl start docker-jackett.service
systemctl stop docker-jackett.service
```

## Examples

### Minimal Configuration

```nix
modules.services.virtualization.containers.jackett = {
  enable = true;
  uid = 1004;
  gid = 1004;
};
```

### Production Configuration

```nix
modules.services.virtualization.containers.jackett = {
  enable = true;

  uid = 1004;
  gid = 1004;

  httpPort = 9117;

  bindMounts = [
    {
      hostPath = "/var/lib/jackett/config";
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
  ];

  backup = {
    enable = true;
    schedule = "0 2 * * *"; # Daily at 2AM
    paths = [ "/var/backups/jackett" "/mnt/backup/jackett" ];
    format = "tar.xz";
    retentionSnapshots = 14;
    maxRetentionDays = 60;
  };

  openFirewallPorts = true;
};
```

## References

- [Jackett GitHub Repository](https://github.com/Jackett/Jackett)
- [Docker Hub Image](https://hub.docker.com/r/linuxserver/jackett/)
- [Jackett Documentation](https://github.com/Jackett/Jackett#readme)
