# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a comprehensive NixOS configuration repository with modular architecture supporting multiple hosts (vd, neo, kiwi) and a modern desktop environment featuring Hyprland, development tools, gaming support, and containerized services.

## Commands

### System Management
- `nixos-rebuild switch --flake .#hostname` - Apply configuration changes for a specific host
- `nixos-rebuild test --flake .#hostname` - Test configuration without persisting
- `nixos-rebuild build --flake .#hostname` - Build configuration only
- `home-manager switch --flake .#hostname@username` - Apply home-manager configuration

### Update Workflow Automation
- `./update.sh` - **Enterprise-grade update workflow** with git integration:
  - Pulls remote changes and detects conflicts
  - Stages all changes automatically
  - Rebuilds NixOS configuration
  - Commits with incrementing messages (Update #1, #2, etc.)
  - Pushes to remote repository
  - Handles error recovery and rollback
  - Provides colored terminal output with status indicators

### Development Environments
- `cd shells/language && nix develop` - Enter language-specific development shell
- Each shell provides complete toolchain (rust-analyzer, python venv, etc.)
- Development shells are completely independent of system configuration

### Maintenance
- `nix-collect-garbage -d` - Clean old generations
- `nix flake update` - Update flake inputs

## Architecture

### Core Structure
- **flake.nix** - Root configuration defining hosts and overlays
- **hosts/** - Host-specific configurations (vd, neo, kiwi)
  - `configuration.nix` - Main system configuration
  - `home.nix` - Home-manager user configuration
  - `hardware-configuration.nix` - Hardware-specific settings

### Modules
- **modules/nixos/** - Reusable system modules organized by function
  - `core/` - Essential system services (audio, networking, security, etc.)
  - `drivers/` - Hardware drivers (nvidia, amd)
  - `display/` - Display managers and desktop environments
  - `services/` - System services (virtualization, networking, storage)

- **modules/home-manager/** - User configuration modules
  - `programs/` - Individual program configurations
  - `configs/` - Application-specific settings (hyprland, waybar, etc.)

### Development Shells
- **shells/** - Language-specific development environments using flakes
  - Each language has its own flake.nix with complete toolchain
  - **Languages**: rust, python3 (CUDA-enabled), go, java, c#, c, php, js, react-native, tauri, unity, maui, pentesting
  - **Special features**: Python shell creates venv automatically, Rust includes cross-compilation targets

### Customizations
- **overlays/** - Custom package modifications and additions (claude-flow, cursor, responsively-app, viber)
- **secrets/** - SOPS-encrypted configuration files (secrets.yaml, ssh.yaml, z-ai.yaml, linux-wallpaperengine.json)
- **config/** - Static configuration files for applications
- **scripts/** - System utility scripts for audio, display, power management, and screenshots

## Module System

The configuration uses a custom module system where hosts enable features through the `modules` option:

```nix
modules = {
  drivers.nvidia.enable = true;
  display.hyprland.enable = true;
  services.virtualization.docker.enable = true;
  # ... other modules
}
```

## Host-Specific Configuration

- **vd** - Desktop workstation with NVIDIA GPU, full development environment, complete virtualization stack
- **neo** - Laptop with AMD GPU, optimized for mobile use (TLP power management, reduced virtualization)
- **kiwi** - Additional host configuration

Each host inherits from common modules but can override settings. The system demonstrates flexibility through different hardware configurations and use cases.

## Development Environment Usage

Development shells are self-contained and can be used independently of the main system configuration:

```bash
cd shells/rust
nix develop  # Enters Rust development environment with rust-analyzer, clippy, etc.
```

## Secret Management

Uses SOPS for encrypted secrets with multiple encrypted files:
- `secrets/secrets.yaml` - General system secrets
- `secrets/ssh.yaml` - SSH key configurations
- `secrets/z-ai.yaml` - AI service configurations
- `secrets/linux-wallpaperengine.json` - Wallpaper engine settings

Secrets are automatically decrypted during system build using SSH keys.

## Advanced Features

### VPN-Aware Docker Networking
Docker configuration uses custom subnets (172.20.0.0/16, 172.21.0.0/16) to avoid conflicts with common VPN ranges, supporting both rootless and NVIDIA GPU-enabled containers.

### Hyprland Configuration Modularity
Hyprland settings are split into logical modules:
- `monitors.nix` - Display-specific configurations
- `keybindings.nix` - Keyboard shortcuts and bindings
- `gestures.nix` - Touchpad/mouse gesture configurations
- `settings.nix` - General Hyprland settings
- `windows.nix` - Window management rules
- `startup.nix` - Application startup configurations

### Enterprise-Grade Update Workflow
The `update.sh` script provides sophisticated automation:
- Remote change detection and conflict handling
- Automatic git staging with intelligent commit messaging
- Colored terminal output with comprehensive error handling
- Rollback capabilities and git state recovery
- Safety checks for sudo privileges and repository state

### AI Development Integration
- **Cursor** - VS Code fork with AI features and custom patches
- **Claude-flow** - Enterprise AI agent orchestration platform
- **aider-chat** - AI-powered pair programming tool
- Multiple AI development environments and configurations