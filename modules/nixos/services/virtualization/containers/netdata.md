# Netdata System Monitoring Module

This module provides a containerized Netdata instance for real-time system monitoring and performance analytics.

## What is Netdata?

Netdata is a real-time performance monitoring tool that provides:

- **Real-time Monitoring**: Live system metrics with sub-second resolution
- **Zero Configuration**: Works out-of-the-box with automatic detection
- **Comprehensive Metrics**: CPU, memory, disk, network, applications, and more
- **Container Monitoring**: Built-in Docker and container monitoring
- **Web Dashboard**: Beautiful, responsive web interface
- **Alerts**: Configurable alerting system
- **Distributed Monitoring**: Monitor multiple systems from one dashboard

## Basic Usage

Enable Netdata in your NixOS configuration:

```nix
{
  modules.services.virtualization.containers.netdata.enable = true;
}
```

After enabling and rebuilding your system, Netdata will be available at:

- **Web Interface**: `http://localhost:19999`

## Port Configuration

Netdata uses the following port:

| Port  | Protocol | Purpose                 |
| ----- | -------- | ----------------------- |
| 19999 | TCP      | Web Dashboard (Default) |

The port is automatically opened in the firewall when the module is enabled.

## Data Persistence

Netdata data is stored in:

- **Config**: `/var/lib/netdata/config` - Configuration files and custom charts
- **Data**: `/var/lib/netdata/lib` - Historical metrics and database
- **Cache**: `/var/lib/netdata/cache` - Temporary data and cache files

These directories are automatically created with proper permissions (0755, owned by `netdata:netdata`).

## Backup Configuration

Enable automatic backups of Netdata data:

```nix
{
  modules.services.virtualization.containers.netdata = {
    enable = true;
    backup = {
      enable = true;
      paths = [ "/var/backups/netdata" "/mnt/backup/netdata" ];
      schedule = "0 2 * * *";  # Daily at 2 AM
      format = "tar.gz";
      retention = 7;  # Keep 7 backups
    };
  };
}
```

**Backup Options:**

- **`enable`**: Enable/disable automatic backups
- **`paths`**: List of backup destination directories (default: `[ "/var/backups/netdata" ]`)
- **`schedule`**: Cron schedule (default: `"0 0 * * *"` = daily at midnight)
- **`format`**: Archive format: `tar.gz`, `tar.xz`, `tar.bz2`, or `zip` (default: `tar.gz`)
- **`retention`**: Number of backups to keep (0 = keep all, default: 7)

**Backup Process:**

1. Stops Netdata systemd service to prevent corruption
2. Creates compressed archive of config, data, and cache directories
3. Copies backup to all configured destination paths
4. Restarts Netdata systemd service
5. Cleans up old backups based on retention policy for each destination
6. Runs automatically according to schedule

**Backup Contents:**

- **Configuration**: Custom charts, alerts, and settings
- **Historical Data**: Metrics database and historical trends
- **Cache**: Temporary data (can be large, consider excluding if space is limited)

## System Access

Netdata requires access to various system resources for comprehensive monitoring:

### Host System Access

- **`/proc`**: Process and system information (read-only)
- **`/sys`**: Kernel and hardware information (read-only)
- **`/etc/os-release`**: Operating system information (read-only)

### Container Monitoring

- **Docker Socket**: `/var/run/docker.sock` for container metrics
- **SYS_PTRACE**: Capability for process monitoring
- **AppArmor**: Unconfined mode for system access

### Network Access

- **Host Network**: Uses `--network=host` for better monitoring accuracy

## Configuration Options

### Image Configuration

Customize the Docker image and tag:

```nix
{
  modules.services.virtualization.containers.netdata = {
    enable = true;
    image = "netdata/netdata";  # Default
    imageTag = "latest";       # Default
  };
}
```

### Custom Port

Change the default port if needed:

```nix
{
  modules.services.virtualization.containers.netdata = {
    enable = true;
    port = 8080;  # Default: 19999
  };
}
```

### Custom Configuration Directory

Specify a custom configuration directory:

```nix
{
  modules.services.virtualization.containers.netdata = {
    enable = true;
    configDirectory = "/storage/netdata/config";
  };
}
```

### GPU Monitoring

Enable GPU monitoring for NVIDIA or AMD graphics cards:

```nix
{
  modules.services.virtualization.containers.netdata = {
    enable = true;
    enableGpuMonitoring = true;
  };
}
```

**GPU monitoring support:**

- **NVIDIA GPUs** (GTX 1060, RTX series, etc.):

  - Requires `modules.drivers.nvidia.enable = true`
  - Uses CDI (Container Device Interface) with `--device=nvidia.com/gpu=all`
  - Provides GPU usage, memory, temperature, and power metrics

- **Intel/AMD GPUs**:
  - Requires appropriate GPU drivers installed
  - Uses `/dev/dri` device access
  - Provides basic GPU metrics and hardware information

## Complete Example

```nix
{
  modules.services.virtualization.containers.netdata = {
    enable = true;

    # Image configuration
    image = "netdata/netdata";
    imageTag = "v1.48.0";  # Specific version

    # Custom port
    port = 8080;

    # Custom configuration directory
    configDirectory = "/storage/netdata/config";

    # Enable GPU monitoring
    enableGpuMonitoring = true;

  };
}
```

## First Time Setup

1. **Navigate** to Netdata web interface:

   - Default: `http://localhost:19999`

2. **Explore the Dashboard**:

   - **System Overview**: CPU, memory, disk, and network usage
   - **Applications**: Running processes and services
   - **Containers**: Docker container metrics (if Docker is running)
   - **Hardware**: GPU, sensors, and hardware information (GPU metrics when `enableGpuMonitoring = true`)

3. **Configure Alerts** (Optional):

   - Navigate to "Alerts" in the sidebar
   - Customize threshold values for various metrics
   - Set up notification methods

4. **Custom Dashboards** (Optional):
   - Create custom charts and dashboards
   - Configure data retention policies
   - Set up data export to external systems

## Monitoring Features

### System Metrics

- **CPU**: Usage, load, frequency, temperature
- **Memory**: RAM usage, swap, buffers, cache
- **Disk**: I/O, space, latency, throughput
- **Network**: Bandwidth, connections, protocols
- **Processes**: Top processes, resource usage

### Container Monitoring

- **Docker**: Container metrics, resource usage
- **Images**: Image sizes and usage
- **Networks**: Container network statistics
- **Volumes**: Storage usage and I/O

### Application Monitoring

- **Web Servers**: Nginx, Apache metrics
- **Databases**: MySQL, PostgreSQL, Redis
- **Services**: Systemd services, custom applications
- **Custom Metrics**: User-defined monitoring points

## Integration with Other Services

### With Portainer

```nix
{
  modules.services.virtualization.containers = {
    netdata.enable = true;
    portainer.enable = true;
  };
}
```

### With Jellyfin

```nix
{
  modules.services.virtualization.containers = {
    netdata.enable = true;
    jellyfin = {
      enable = true;
      mediaDirectories = [ "/media" ];
      enableHardwareAcceleration = true;
    };
  };
}
```

### Complete Monitoring Stack

```nix
{
  modules.services.virtualization = {
    docker = {
      enable = true;
      devtools = true;
    };

    containers = {
      netdata = {
        enable = true;
        image = "netdata/netdata";
        imageTag = "v1.47.4";
      };
      portainer = {
        enable = true;
        image = "portainer/portainer-ce";
        imageTag = "latest";
      };
      jellyfin = {
        enable = true;
        mediaDirectories = [ "/media" ];
        enableHardwareAcceleration = true;
      };
    };
  };
}
```

## Network Access

The module automatically opens the required firewall port:

- **TCP**: 19999 (configurable via `port` option)

## Troubleshooting

### Service Not Starting

- Check service status: `systemctl status docker-netdata.service`
- View logs: `journalctl -u docker-netdata.service`
- Ensure Docker is running: `systemctl status docker.service`

### Cannot Access Web Interface

- Verify port is open: `ss -tlnp | grep 19999`
- Check firewall: `sudo iptables -L | grep 19999`
- Try accessing via IP: `http://YOUR_IP:19999`

### Permission Issues

- Verify system access: `ls -la /proc /sys /etc/os-release`
- Check Docker socket: `ls -la /var/run/docker.sock`
- Ensure user has proper permissions: `groups netdata`

### Missing Metrics

- **Container Metrics**: Ensure Docker is running and socket is accessible
- **Hardware Metrics**: Check if hardware sensors are available
- **Custom Metrics**: Verify application-specific collectors are enabled

### Performance Issues

- **High CPU Usage**: Adjust data collection frequency in configuration
- **Memory Usage**: Configure data retention policies
- **Disk Space**: Monitor cache and data directory sizes

### Service Health Monitoring

- Check if Netdata is responding: `curl -f http://localhost:19999`
- Verify container is running: `docker ps | grep netdata`
- Check container logs: `docker logs netdata`
- Monitor service status: `systemctl status docker-netdata.service`

### GPU Monitoring Issues

**For NVIDIA GPUs:**

- Verify `nvidia-smi` works on the host system
- Check that `modules.drivers.nvidia.enable = true` in your configuration
- Ensure Docker NVIDIA support is enabled: `services.virtualization.docker.nvidia = true`
- Verify CDI devices are available: `nvidia-ctk cdi list` (should show `nvidia.com/gpu=all`)
- Check if GPU metrics appear in Netdata dashboard under "Hardware" section

**For Intel/AMD GPUs:**

- Check that GPU drivers are properly installed
- Verify `/dev/dri` devices exist and are accessible: `ls -la /dev/dri`
- Ensure the container has access to GPU devices
- Check if GPU metrics appear in Netdata dashboard under "Hardware" section

## Advanced Configuration

### Custom Configuration

Create custom configuration files in `/var/lib/netdata/config/`:

```bash
# Example: Custom chart configuration
sudo mkdir -p /var/lib/netdata/config/charts.d
sudo nano /var/lib/netdata/config/charts.d/custom.conf
```

### Data Retention

Configure data retention in `/var/lib/netdata/config/netdata.conf`:

```ini
[global]
    history = 3600  # 1 hour of 1-second data
    memory mode = dbengine
    page cache size = 32
    dbengine multihost disk space = 256
```

### Alert Configuration

Set up custom alerts in `/var/lib/netdata/config/health_alarm_notify.conf`:

```bash
# Example: Email notifications
sudo nano /var/lib/netdata/config/health_alarm_notify.conf
```

### External Monitoring

Connect to external monitoring systems:

- **Prometheus**: Enable Prometheus endpoint
- **Grafana**: Use as data source
- **InfluxDB**: Export metrics to time-series database

## Security Considerations

### Access Control

- **Default Access**: Web interface is accessible to anyone on the network
- **Authentication**: Consider setting up authentication for production use
- **Network Security**: Use reverse proxy with SSL/TLS for secure access

### System Access

- **Privileged Access**: Netdata requires system-level access for comprehensive monitoring
- **Docker Socket**: Full access to container information
- **Process Monitoring**: Can see all running processes and their resource usage

### Data Privacy

- **Metrics Collection**: Collects detailed system and application metrics
- **Data Storage**: Historical data is stored locally
- **Network Exposure**: Metrics can be exposed to external monitoring systems

## Alternatives

Consider these alternatives based on your monitoring needs:

- **Prometheus + Grafana**: More complex but highly scalable monitoring stack
- **Zabbix**: Enterprise-grade monitoring with advanced features
- **Nagios**: Traditional monitoring with extensive plugin ecosystem
- **htop/iotop**: Simple command-line monitoring tools (included with module)
- **Glances**: Python-based monitoring with web interface
