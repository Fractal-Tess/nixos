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

### Development Environments
- `nix develop ./shells/language/` - Enter development shell for specific language (rust, python3, go, etc.)
- `nix develop` - Use default development shell in language directories

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
  - Each language has its own flake.nix with appropriate toolchain
  - Supports: rust, python3, go, java, c#, c, php, js, react-native, tauri, unity, maui

### Customizations
- **overlays/** - Custom package modifications and additions
- **secrets/** - SOPS-encrypted configuration files
- **config/** - Static configuration files for applications

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

- **vd** - Desktop workstation with NVIDIA GPU, full development environment
- **neo** - Laptop configuration
- **kiwi** - Additional host configuration

Each host inherits from the common modules but can override settings as needed.

## Development Environment Usage

Development shells are self-contained and can be used independently of the main system configuration:

```bash
cd shells/rust
nix develop  # Enters Rust development environment with rust-analyzer, clippy, etc.
```

## Secret Management

Uses SOPS for encrypted secrets. SSH keys and sensitive configuration are stored in the `secrets/` directory and decrypted during system build.