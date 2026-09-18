# Fractal-Tess's NixOS Configuration

![NixOS Configuration](image.png)

A modular NixOS and Home Manager configuration for three systems, with shared desktop, development, gaming, networking, and service modules.

## Highlights

- **Hyprland desktop** with Waybar and ReGreet
- **Home Manager** for user applications and dotfiles
- **SOPS** for encrypted secrets management
- **Development shells** for Rust, Python, Go, JavaScript, Java, C#, C, PHP, Tauri, React Native, Unity, pentesting, and Playwright
- **Containers and virtualization** with Docker and related services
- **Custom packages and fixes** through Nix overlays

## Hosts

| Host | Type |
| --- | --- |
| `vd` | Desktop |
| `neo` | Laptop |
| `kiwi` | Laptop |

## Repository Layout

- `hosts/` — host-specific NixOS and Home Manager configuration
- `modules/nixos/` — reusable system modules
- `modules/home-manager/` — reusable user modules
- `config/` and `dotfiles/` — application configuration
- `overlays/` — package overrides and additions
- `scripts/` — system and development utilities
- `secrets/` — SOPS-encrypted secrets
- `shells/` — language-specific development flakes

## Usage

Build a host configuration from the repository root:

```sh
sudo nixos-rebuild build --flake .#<hostname> --impure
```

Replace `<hostname>` with `vd`, `neo`, or `kiwi`.

Apply the local host configuration with the repository helper:

```sh
./scripts/nixos/update
```

## Application modules

Application repos keep their source names (`scorch`, `shadoword`, etc.).
Third-party packaging repos use `-flake` (`oh-my-pi-flake`, `open-design-flake`,
`responsively-flake`). Both expose modules with `enable` and `package` options.
Versions come from the input revision and `flake.lock`, not a separate version string.

System module imports live in
[`modules/nixos/applications`](modules/nixos/applications/default.nix);
user module imports live in
[`modules/home-manager/applications`](modules/home-manager/applications/default.nix).
These files expose options without enabling applications.
Each host's `applications.nix` owns its project configuration:
[`vd`](hosts/vd/applications.nix), [`neo`](hosts/neo/applications.nix),
and [`kiwi`](hosts/kiwi/applications.nix). User-service settings go inside
`home-manager.users.${username}` in that same file; general Home Manager
configuration stays in `home.nix`.

```nix
# In hosts/<host>/applications.nix
programs.omp.enable = true;
programs.responsively.enable = true;
services.scorchd.autoStart = false; # keep a unit for manual starts

# User services, in the same NixOS module
home-manager.users.${username} = {
  services.clip-sync.enable = true;
  services.shadoword-desktop.enable = true;
};
```

Service environment overrides use `environment`. Open Design's NixOS facade
takes typed options directly alongside `user`; it requires Home Manager.
Runtime secrets stay in secret files. Disabling a module does not delete its data.

For a new program flake, initialize the runnable Hello example from another directory:
`nix flake init -t /path/to/nixos#program-module`.

> This is a personal configuration. Review host settings, hardware configuration, users, and secrets before adapting it to another machine.

---

_Built with NixOS_
