# CRUSH Agent Configuration

## Build/Lint/Test Commands
- Build system: `nixos-rebuild build`
- Switch system: `nixos-rebuild switch`
- Test single file: Not applicable for NixOS (uses module system)
- Lint: Not applicable for Nix (syntax checked by nixos-rebuild)

## Code Style Guidelines
- Follow NixOS module structure with imports, options, and config sections
- Use `mkIf`, `mkDefault`, `mkMerge` for conditional configuration
- Place service modules in `modules/nixos/services/[service]/`
- Use SOPS for secret management with modular approach
- Store secrets in `/run/secrets/` with restricted permissions (0400)
- Structure Samba shares with proper security settings (no guest access)
- Use activation scripts for user management from SOPS secrets
- Follow security best practices: avoid plaintext passwords, use descriptive names
- File permissions: SSH files owner=username, service passwords owner=root

## Cursor Rules
- NixOS module structure and coding standards
- Project structure and organization
- Samba configuration patterns
- SOPS secrets management

## Naming Conventions
- Use descriptive option names and descriptions
- Use lowercase with hyphens for multi-word names
- Follow DRY principle (Don't Repeat Yourself)

## File Organization
- Service modules: `modules/nixos/services/[service]/[submodule].nix`
- Host configs: `hosts/[host]/configuration.nix`
- SOPS secrets: `secrets/secrets.yaml`
- Docs: `[module]/README.md`