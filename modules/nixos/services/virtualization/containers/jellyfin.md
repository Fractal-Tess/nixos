# Jellyfin Media Server Module

This module provides a containerized Jellyfin media server using OCI containers.

## Basic Usage

Enable Jellyfin in your NixOS configuration:

```nix
{
  modules.services.virtualization.jellyfin = {
    enable = true;
    mediaDirectories = [
      "/media/movies"
      "/media/tv"
      "/media/music"
    ];
  };
}
```

**Note:** `mediaDirectories` is required and must be specified.

After enabling, Jellyfin will be available at:

- HTTP: `http://localhost:8096`
- HTTPS: `https://localhost:8920` (if configured)

## Configuration Options

### Media Directories

Configure which directories contain your media files:

```nix
{
  modules.services.virtualization.jellyfin = {
    enable = true;
    mediaDirectories = [
      "/media/movies"
      "/media/tv"
      "/media/music"
      "/media/audiobooks"
    ];
  };
}
```

Media directories are mounted as read-only inside the container.

### Port Configuration

Customize the ports Jellyfin uses:

```nix
{
  modules.services.virtualization.jellyfin = {
    enable = true;
    httpPort = 8080;   # Default: 8096
    httpsPort = 8443;  # Default: 8920
  };
}
```

### Hardware Acceleration

Enable hardware acceleration for video transcoding (requires appropriate GPU drivers):

```nix
{
  modules.services.virtualization.jellyfin = {
    enable = true;
    enableHardwareAcceleration = true;
  };
}
```

**Hardware acceleration support:**

- **NVIDIA GPUs** (GTX 1060, RTX series, etc.):

  - Requires `modules.drivers.nvidia.enable = true`
  - Uses CDI (Container Device Interface) with `--device=nvidia.com/gpu=all`
  - Automatically configured for compute and video encoding/decoding

- **Intel/AMD GPUs**:
  - Requires appropriate GPU drivers installed
  - Uses `/dev/dri` device access
  - User needs access to video devices

**For your NVIDIA GTX 1060**: Simply enable hardware acceleration and ensure NVIDIA drivers are enabled in your host configuration.

### User/Group Configuration

Customize the user and group Jellyfin runs as:

```nix
{
  modules.services.virtualization.jellyfin = {
    enable = true;
    user = "media";
    group = "media";
  };
}
```

## Complete Example

```nix
{
  modules.services.virtualization.jellyfin = {
    enable = true;

        # Media directories
    mediaDirectories = [
      "/storage/movies"
      "/storage/tv"
      "/storage/music"
    ];

    # Custom ports
    httpPort = 8080;
    httpsPort = 8443;

    # Enable hardware acceleration
    enableHardwareAcceleration = true;

    # Custom user/group
    user = "media";
    group = "media";
  };
}
```

## Data Persistence

Jellyfin data is stored in:

- **Config**: `/var/lib/jellyfin/config` - Jellyfin configuration files
- **Cache**: `/var/lib/jellyfin/cache` - Transcoding cache and thumbnails
- **Logs**: `/var/lib/jellyfin/log` - Application logs

These directories are automatically created with proper permissions.

## Network Access

The module automatically opens the required firewall ports:

- **TCP**: HTTP and HTTPS ports (default: 8096, 8920)
- **UDP**: 7359 (local discovery), 1900 (DLNA/UPnP)

## First Time Setup

1. Navigate to the Jellyfin web interface (default: `http://localhost:8096`)
2. Follow the setup wizard to:
   - Create an admin account
   - Add media libraries pointing to your mounted directories
   - Configure transcoding settings (if using hardware acceleration)

## Troubleshooting

### Media Not Visible

- Ensure media directories exist and have proper permissions
- Check that directories are correctly mounted in the container
- Verify file ownership matches the configured user/group

### Hardware Acceleration Issues

**For NVIDIA GPUs:**

- Verify `nvidia-smi` works on the host system
- Check that `modules.drivers.nvidia.enable = true` in your configuration
- Ensure Docker NVIDIA support is enabled: `services.virtualization.docker.nvidia = true`
- Verify CDI devices are available: `nvidia-ctk cdi list` (should show `nvidia.com/gpu=all`)
- Check container logs: `journalctl -u docker-jellyfin.service`
- If CDI issues persist, try: `sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml`

**For Intel/AMD GPUs:**

- Check that GPU drivers are properly installed
- Verify `/dev/dri` devices exist and are accessible
- Ensure the container has access to GPU devices

### Permission Issues

- Verify media directories have read permissions for the Jellyfin user
- Check systemd logs: `journalctl -u docker-jellyfin.service`
