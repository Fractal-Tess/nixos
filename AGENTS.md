# AGENTS.md

This document contains essential information for agentic coding assistants working in this NixOS configuration repository.

## Build / Lint / Test Commands

### Primary Commands
- **Rebuild system**: `sudo nixos-rebuild switch --flake .#<hostname> --impure`
- **Update everything**: `./update.sh` (handles git pull, rebuild, commit, push)
- **Build only (dry-run)**: `sudo nixos-rebuild build --flake .#<hostname> --impure`
- **Update flake inputs**: `nix flake update`

### Hostnames
- `vd` - Desktop (main system)
- `neo` - Laptop
- `kiwi` - Laptop

### Development Shells
- Enter any language shell: `nix develop` from `shells/<language>/`
- Available shells: rust, python, go, js, java, csharp, c, php, tauri, react-native, unity, pentesting, playwright

### Nix Commands
- **Check configuration**: `nix flake check`
- **Show derivation tree**: `nix show-derivation .#<hostname>`
- **Search packages**: `nix search nixpkgs <package>`
- **Run package temporary**: `nix run nixpkgs#<package>`

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
{ ... }:
{ config, lib, username, ... }:

# Shell flakes
{ self, systems, nixpkgs, ... }@inputs:

# Overlays
final: prev:
```

### Section Organization
Use comment block dividers for major sections:
```nix
#===...===#
# IMPORTS
#===...===#
imports = [ ... ];

#===...===#
# OPTIONS
#===...===#
options.modules.services.something.enable = mkEnableOption "description";

#===...===#
# CONFIG
#===...===#
config = mkIf cfg.enable { ... };
```

### Module Patterns
- Enable options: `mkEnableOption "<description>"`
- Conditional config: `mkIf cfg.enable { ... }`
- Default values: `mkDefault <value>`
- Use `with lib;` at function start for convenience

### Imports
- Use relative paths: `./<file>.nix` or `../../<path>/<file>.nix`
- External inputs via `inputs.<name>.<module>` (defined in flake.nix)
- Group imports by type: hardware, external, custom modules

### Naming Conventions
- Module options: `config.modules.<category>.<name>.enable`
- Enable flags: `enable`, `<service>.enable`
- Files: kebab-case for modules (`boot.nix`, `networking.nix`)
- Host directories: lowercase hostname (`vd/`, `neo/`)

### Attribute Sets
- Use `with pkgs;` for package lists
- Multi-line lists: bracket on opening line
```nix
fonts.packages = with pkgs; [
  nerd-fonts.caskaydia-cove
  nerd-fonts.jetbrains-mono
  cascadia-code
];
```

### Comments
- Section dividers: `#===...===#`
- Inline comments: `# Comment`
- Document special cases: `# NOTE: reason for unusual config`
- Comment out alternatives rather than delete

### Configuration Values
- Use `mkDefault` for sensible defaults
- Hardcode system values only in host configs
- Use `inherit` for passing parameters: `{ inherit inputs username; }`

### Error Handling
- No exception handling (Nix is functional/declarative)
- Use `mkIf` for conditional configuration
- Use `lib.optionals` for optional lists
- Handle missing modules with imports array

### Special NixOS Patterns
- Custom modules namespace: `config.modules.<category>.<name>.<option>`
- Enable pattern in host configs:
```nix
modules = {
  display.hyprland.enable = true;
  services.sshd.enable = true;
};
```
- Home Manager integration:
```nix
home-manager = {
  useGlobalPkgs = true;
  useUserPackages = true;
  users."${username}" = import ./home.nix;
};
```

### Overlay Format
```nix
final: prev: {
  <package> = prev.<package>.overrideAttrs (oldAttrs: rec {
    <options>
  });
}
```

## Testing Guidelines

- No automated tests (this is declarative system config)
- Test by rebuilding: `sudo nixos-rebuild switch --flake .#<hostname>`
- Test modules by enabling in host config and rebuilding
- Check configuration validity: `nix flake check`

## Repository Conventions

- Main branch: `main`
- Commit messages via `update.sh`: `Update #<number>` (auto-incremented)
- All changes tracked in git (flake.lock included)
- Secrets encrypted with SOPS in `secrets/` directory

## Important Notes

- Always rebuild after changing flake.nix
- Flakes require `experimental-features = [ "nix-command" "flakes" ]`
- Use `--impure` flag for flake rebuilds (needed for host detection)
- Hardware configs are auto-generated, edit with caution
- User modules are under `modules/home-manager/`, system under `modules/nixos/`
