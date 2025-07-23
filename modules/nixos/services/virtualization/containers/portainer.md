# Portainer Container Management Module

This module provides a containerized Portainer Community Edition (CE) instance for managing Docker containers and services through a web interface.

## What is Portainer?

Portainer is a lightweight container management UI that allows you to easily manage your Docker containers, images, volumes, and networks through a web-based interface. It's perfect for:

- **Container Management**: Start, stop, restart, and monitor containers
- **Image Management**: Pull, build, and manage Docker images
- **Volume & Network Management**: Manage Docker volumes and networks
- **Stack Deployment**: Deploy multi-container applications using Docker Compose
- **User Management**: Multi-user access with role-based permissions

## Basic Usage

Enable Portainer in your NixOS configuration:

```nix
{
  modules.services.virtualization.containers.portainer.enable = true;
}
```

After enabling and rebuilding your system, Portainer will be available at:

- **HTTP**: `http://localhost:9000`
- **HTTPS**: `https://localhost:9443`

## Port Configuration

Portainer uses the following ports:

| Port | Protocol | Purpose                      |
| ---- | -------- | ---------------------------- |
| 8000 | TCP      | Edge Agent communication     |
| 9000 | TCP      | HTTP Web Interface (Primary) |
| 9443 | TCP      | HTTPS Web Interface (Secure) |

All ports are automatically opened in the firewall when the module is enabled.

## Data Persistence

Portainer data is stored in:

- **Data Directory**: `/var/lib/portainer` - User accounts, settings, templates, and configurations

This directory is automatically created with proper permissions (0750, owned by `portainer:docker`).

## Security Considerations

### Access Control

- **First-time Setup**: The first user to access Portainer becomes the admin
- **Default Access**: HTTP interface is unencrypted (consider using HTTPS on port 9443)
- **Docker Socket**: Full access to Docker daemon via `/var/run/docker.sock`

### Important Security Notes

- Portainer has **full control** over your Docker environment
- Anyone with access to Portainer can manage all containers
- Consider using HTTPS (port 9443) for production environments
- The service runs as a dedicated `portainer` system user

## Docker Socket Access

The module mounts the Docker socket at `/run/user/1000/docker.sock:/var/run/docker.sock`, providing:

- Full container lifecycle management
- Image and volume operations
- Network configuration
- Service management

## Complete Example

```nix
{
  # Enable Docker with Portainer
  modules.services.virtualization = {
    docker = {
      enable = true;
      rootless = true;  # Optional: rootless Docker
      devtools = true;  # Optional: additional Docker tools
    };

    containers.portainer.enable = true;
  };
}
```

## First Time Setup

1. **Navigate** to Portainer web interface:

   - HTTP: `http://localhost:9000`
   - HTTPS: `https://localhost:9443` (recommended)

2. **Create Admin Account**:

   - Set a strong password for the admin user
   - This will be the primary administrator account

3. **Environment Setup**:

   - Portainer will automatically detect your local Docker environment
   - Click "Local" to manage the local Docker instance

4. **Explore the Interface**:
   - **Containers**: View and manage running containers
   - **Images**: Browse and manage Docker images
   - **Volumes**: Manage persistent storage
   - **Networks**: Configure container networking
   - **Stacks**: Deploy multi-container applications

## Usage Examples

### Managing Containers

- **View All Containers**: Navigate to "Containers" in the sidebar
- **Start/Stop**: Use action buttons next to each container
- **View Logs**: Click on container name → "Logs" tab
- **Access Console**: Click "Console" to open terminal access

### Deploying Stacks

- **Navigate**: Go to "Stacks" in the sidebar
- **Add Stack**: Click "Add stack"
- **Docker Compose**: Paste your `docker-compose.yml` content
- **Deploy**: Click "Deploy the stack"

### Image Management

- **Pull Images**: Go to "Images" → "Build a new image"
- **Build**: Upload Dockerfile or use Git repository
- **Registry**: Configure access to private registries

## Network Access

The module automatically opens the required firewall ports:

- **TCP**: 8000 (Edge Agent), 9000 (HTTP), 9443 (HTTPS)

## Troubleshooting

### Service Not Starting

- Check service status: `systemctl status docker-portainer.service`
- View logs: `journalctl -u docker-portainer.service`
- Ensure Docker is running: `systemctl status docker.service`

### Cannot Access Web Interface

- Verify ports are open: `ss -tlnp | grep -E "(8000|9000|9443)"`
- Check firewall: `sudo iptables -L | grep -E "(8000|9000|9443)"`
- Try alternative port (HTTP vs HTTPS)

### Permission Issues

- Verify Docker socket access: `ls -la /run/user/1000/docker.sock`
- Check container logs: `docker logs portainer`
- Ensure user is in docker group: `groups $USER`

### Container Management Issues

- **Docker Socket**: Ensure `/var/run/docker.sock` is accessible
- **Rootless Docker**: May require different socket path configuration
- **SELinux/AppArmor**: Check security policies if containers can't be managed

### Data Loss Prevention

- **Backup**: Regular backup of `/var/lib/portainer`
- **Volumes**: Ensure persistent volumes are properly configured
- **Updates**: Data directory persists across container updates

## Integration with Other Services

### With Jellyfin

```nix
{
  modules.services.virtualization.containers = {
    portainer.enable = true;
    jellyfin = {
      enable = true;
      mediaDirectories = [ "/media" ];
      enableHardwareAcceleration = true;
    };
  };
}
```

### With Development Tools

```nix
{
  modules.services.virtualization = {
    docker = {
      enable = true;
      devtools = true;  # Includes dive, lazydocker, buildkit
    };
    containers.portainer.enable = true;
  };
}
```

## Advanced Configuration

While the current module provides basic Portainer setup, you can extend functionality by:

1. **Custom Networks**: Create isolated networks through Portainer UI
2. **Registry Integration**: Connect private Docker registries
3. **Template Management**: Create custom application templates
4. **Edge Agent**: Manage remote Docker environments
5. **RBAC**: Set up role-based access control for teams

## Alternatives

Consider these alternatives based on your needs:

- **Lazydocker**: Terminal-based Docker management (`modules.services.virtualization.docker.devtools = true`)
- **Docker Desktop**: Full desktop application (not available on NixOS)
- **Portainer Business**: Enterprise features (requires license)
- **Rancher**: Full Kubernetes and container management platform
