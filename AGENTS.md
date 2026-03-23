# AGENTS.md

This document contains essential information for agentic coding assistants working in this NixOS configuration repository.

## Build / Lint / Test Commands

### Primary Commands
- **Rebuild system**: `./scripts/nixos/update` (preferred — stages changes, rebuilds, generates AI commit message, commits and pushes automatically)
- **Build only (dry-run)**: `sudo nixos-rebuild build --flake .#<hostname> --impure`
- **Update flake inputs**: `nix flake update`
- **Check configuration**: `nix flake check`
- **Format Nix files**: `nix fmt` — **always run after making any changes to Nix files**

### Hostnames
- `vd` - Desktop
- `neo` - Laptop
- `kiwi` - Laptop

### Development Shells
- Enter any language shell: `nix develop` from `shells/<language>/`
- Available shells: rust, python, go, js, java, csharp, c, php, tauri, react-native, unity, pentesting, playwright

### Secrets (SOPS)
- Edit secrets: `sops secrets/secrets.yaml`
- Update age key: Ensure `/home/<username>/.config/sops/age/keys.txt` exists

## Code Style Guidelines

### File Structure
- NixOS system modules: `modules/nixos/<category>/<module>.nix`
- Home Manager modules: `modules/home-manager/<category>/<module>.nix`
- Host configs: `hosts/<hostname>/configuration.nix`
- Shell environments: `shells/<language>/flake.nix`

### Function Signatures
```nix
# System modules
{ config, lib, pkgs, ... }:

# Shell flakes
{ self, systems, nixpkgs, ... }@inputs:

# Overlays
final: prev:
```

### Section Organization
Use comment block dividers for major sections:
```nix
#============================================================================
# IMPORTS
#============================================================================
imports = [ ... ];

#============================================================================
# OPTIONS
#============================================================================
options.modules.services.something.enable = mkEnableOption "description";

#============================================================================
# CONFIG
#============================================================================
config = mkIf cfg.enable { ... };
```

### Module Patterns
- Enable options: `mkEnableOption "<description>"`
- Conditional config: `mkIf cfg.enable { ... }`
- Default values: `mkDefault <value>`
- Use `with lib;` at function start for convenience
- Define `cfg` binding: `let cfg = config.modules.<category>.<name>; in`
- Custom modules namespace: `config.modules.<category>.<name>.<option>`
- Enable pattern in host configs:
```nix
modules = {
  display.hyprland.enable = true;
  services.sshd.enable = true;
};
```

## Important Notes

- **Always run `./scripts/nixos/update` after making changes to any Nix-related module** to rebuild and verify the configuration. Do this automatically without asking or informing the user, unless the user explicitly asks not to rebuild.
- Always rebuild after changing flake.nix
- Use `--impure` flag for flake rebuilds (needed for host detection)
- User modules are under `modules/home-manager/`, system under `modules/nixos/`
- Check for existing modules before creating new ones
