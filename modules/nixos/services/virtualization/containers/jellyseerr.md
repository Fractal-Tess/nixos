# Jellyseerr Container Module

## Overview

Jellyseerr is a request management system for Jellyfin that allows users to request movies and TV shows. It integrates with various services like Sonarr, Radarr, and Overseerr to automate the process of finding and downloading content.

## Features

- **Request Management**: Users can request movies and TV shows through a web interface
- **Jellyfin Integration**: Seamlessly integrates with Jellyfin media server
- **Automation**: Automatically forwards approved requests to download managers
- **User Management**: Role-based access control for different user types
- **Media Discovery**: Browse and search for content using TMDb and other sources

## Configuration

### Basic Configuration

```nix
modules.services.virtualization.containers.jellyseerr = {
  enable = true;

  # Custom port (default: 5055)
  webPort = 5055;

  # Open firewall ports
  openFirewallPorts = true;
};
```

### Advanced Configuration

```nix
modules.services.virtualization.containers.jellyseerr = {
  enable = true;

  # Custom user configuration
  user = {
    name = "jellyseerr";
    uid = 1007;
    gid = 1007;
  };

  # Custom image and tag
  image = "fallenbagel/jellyseerr";
  imageTag = "latest";

  # Custom bind mounts
  bindMounts = [
    {
      hostPath = "/var/lib/jellyseerr/config";
      containerPath = "/app/config";
      readOnly = false;
      backup = true;
    }
    {
      hostPath = "/var/lib/jellyseerr/cache";
      containerPath = "/app/cache";
      readOnly = false;
      backup = false;
    }
    {
      hostPath = "/media/movies";
      containerPath = "/media/movies";
      readOnly = true;
      backup = false;
    }
  ];

  # Backup configuration
  backup = {
    enable = true;
    schedule = "0 0 * * *"; # Daily at midnight
    paths = [ "/var/backups/jellyseerr" "/mnt/backup/jellyseerr" ];
    format = "tar.gz";
    maxRetentionDays = 30;
    retentionSnapshots = 10;
  };
};
```

## Default Bind Mounts

The module creates the following default bind mounts:

- **Config**: `/var/lib/jellyseerr/config` → `/app/config` (backed up)
- **Cache**: `/var/lib/jellyseerr/cache` → `/app/cache` (not backed up)

## Port Configuration

- **Default Port**: 5055
- **Container Port**: 5055 (internal)
- **Protocol**: HTTP

## Environment Variables

The container automatically sets these environment variables:

- `PUID`: User ID for file permissions
- `PGID`: Group ID for file permissions
- `TZ`: System timezone

## Backup and Restore

### Automatic Backups

When enabled, the module provides:

- **Daily backups** of configuration data
- **Configurable retention** policies
- **Multiple backup destinations** support
- **Compressed archives** in various formats

### Manual Restore

Use the provided restore script:

```bash
sudo systemctl start jellyseerr-restore
```

## Integration

### Jellyfin Setup

1. Add Jellyseerr as a plugin in Jellyfin
2. Configure the connection settings
3. Set up user roles and permissions

### Download Managers

Jellyseerr can integrate with:

- **Sonarr**: TV show management
- **Radarr**: Movie management
- **Lidarr**: Music management
- **Readarr**: Book management

## Security Considerations

- **Network Mode**: Uses host networking for better service discovery
- **User Isolation**: Runs as dedicated system user (configurable)
- **File Permissions**: Proper ownership and permissions for data directories
- **Firewall**: Optional port opening for external access

## Troubleshooting

### Common Issues

1. **Permission Errors**: Ensure data directories have correct ownership
2. **Connection Issues**: Check firewall settings and network configuration
3. **Service Not Starting**: Verify Docker service is running

### Logs

Check container logs:

```bash
sudo journalctl -u docker-jellyseerr.service
```

### Data Directory Permissions

If using custom user, ensure proper ownership:

```bash
sudo chown -R jellyseerr:jellyseerr /var/lib/jellyseerr
sudo chmod -R 755 /var/lib/jellyseerr
```

## Dependencies

- Docker/OCI containers support
- Backup utility functions
- Systemd services and timers
- User and group management

## References

- [Docker Hub Image](https://hub.docker.com/r/fallenbagel/jellyseerr)
- [GitHub Repository](https://github.com/Fallenbagel/jellyseerr)
- [Documentation](https://docs.jellyseerr.com/)
