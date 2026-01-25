# Packaging AppImages for NixOS

This guide explains how to create NixOS packages from AppImage files and integrate them with your desktop environment.

## Overview

AppImages are self-contained Linux applications. To properly package them for NixOS, we need to:
1. Download and hash the AppImage
2. Create a NixOS overlay
3. Add the overlay to your flake
4. Include the package in your host configuration
5. Add desktop integration (optional but recommended)

## Step-by-Step Guide

### 1. Get the AppImage URL and Hash

First, find the direct download URL for the AppImage. For GitHub releases, the URL format is typically:
```
https://github.com/<owner>/<repo>/releases/download/<tag>/<filename>.AppImage
```

Download and compute the hash:
```bash
nix-prefetch-url https://github.com/owner/repo/releases/download/v1.0.0/App_1.0.0_amd64.AppImage
```

This returns a hash like: `193n0z10nl4apgnvlp4m224m2jdj1jsdj6vhdi66ng62h8ak0fxm`

Convert to SRI format:
```bash
nix hash to-sri --type sha256 193n0z10nl4apgnvlp4m224m2jdj1jsdj6vhdi66ng62h8ak0fxm
```

This returns: `sha256-tTswFYLCPGtMbHAb2bQMsklRiRCVXLrtu4pQC8IHdqQ=`

### 2. Create an Overlay File

Create a new file in `overlays/<appname>.nix`:

```nix
self: super: {
  # Overlay for AppName - Brief description
  appname = super.stdenv.mkDerivation rec {
    pname = "appname";
    version = "1.0.0";

    src = super.fetchurl {
      url = "https://github.com/owner/repo/releases/download/v${version}/App_${version}_amd64.AppImage";
      sha256 = "sha256-YOUR_HASH_HERE=";
    };

    dontUnpack = true;
    nativeBuildInputs = [ super.makeWrapper ];
    buildInputs = [ super.appimage-run ];

    installPhase = ''
      # Store the AppImage in $out/opt
      mkdir -p $out/opt
      cp $src $out/opt/AppName.AppImage
      chmod +x $out/opt/AppName.AppImage

      # Create a wrapper script in $out/bin
      mkdir -p $out/bin
      cat > $out/bin/appname <<EOF
      #!${super.stdenv.shell}
      exec ${super.appimage-run}/bin/appimage-run $out/opt/AppName.AppImage "$@"
      EOF
      chmod +x $out/bin/appname

      # Create desktop entry for application launcher
      mkdir -p $out/share/applications
      cat > $out/share/applications/appname.desktop <<EOF
      [Desktop Entry]
      Name=AppName
      Comment=Brief description of the application
      Exec=$out/bin/appname
      Icon=appropriate-icon-name
      Terminal=false
      Type=Application
      Categories=Utility;
      Keywords=keyword1;keyword2;keyword3;
      StartupWMClass=AppName
      EOF
    '';

    meta = with super.lib; {
      description = "Full description of the application";
      homepage = "https://github.com/owner/repo";
      license = licenses.mit;  # Adjust to actual license
      platforms = platforms.linux;
      maintainers = with maintainers; [ ];
    };
  };
}
```

### 3. Add Overlay to flake.nix

Edit your `flake.nix` and add the overlay to the `nixpkgs.overlays` list:

```nix
nixpkgs.overlays = [
  # ... existing overlays ...
  (import ./overlays/appname.nix)
];
```

### 4. Add Package to Host Configuration

Edit your host's `packages.nix` (e.g., `hosts/vd/packages.nix`) and add the package:

```nix
environment.systemPackages = with pkgs; [
  # ... existing packages ...
  appname  # Your new AppImage package
];
```

### 5. Build and Test

Stage the files in git (flakes only use tracked files):
```bash
git add overlays/appname.nix flake.nix hosts/vd/packages.nix
```

Rebuild your system:
```bash
sudo nixos-rebuild switch --flake .#hostname
```

Test the application:
```bash
which appname  # Should show the binary in your PATH
appname        # Launch the application
```

## Desktop Integration Details

### Desktop File Fields

The `.desktop` file should include these key fields:

- **Name**: Display name in the launcher
- **Comment**: Short description (appears as tooltip)
- **Exec**: Full path to the executable (use `$out/bin/appname`)
- **Icon**: Icon name from system theme or path to custom icon
- **Terminal**: Set to `false` for GUI apps, `true` for terminal apps
- **Type**: Usually `Application`
- **Categories**: Semicolon-separated list (see categories below)
- **Keywords**: Semicolon-separated search terms
- **StartupWMClass**: Window class name (helps with window grouping)

### Common Categories

Choose appropriate categories from the [freedesktop.org specification](https://specifications.freedesktop.org/menu-spec/latest/apa.html):

- **Development**: IDEs, text editors, debuggers
- **Office**: Word processors, spreadsheets, presentation tools
- **Graphics**: Image editors, viewers, 3D modeling
- **AudioVideo**: Media players, editors, recorders
- **Network**: Web browsers, email clients, chat applications
- **Utility**: File managers, terminals, system tools
- **Game**: Games and game launchers

### Common Icon Names

Use system-provided icons when possible:

- `audio-input-microphone` - For audio/speech apps
- `text-editor` - For text editors
- `web-browser` - For web browsers
- `multimedia-video-player` - For video players
- `applications-development` - For development tools
- `preferences-system` - For system utilities
- `applications-games` - For games

Browse available icons:
```bash
ls /run/current-system/sw/share/icons/hicolor/*/apps/
```

### Custom Icons

If you need a custom icon, extract it from the AppImage and include it:

```nix
installPhase = ''
  # ... existing code ...

  # Extract and install icon
  mkdir -p $out/share/icons/hicolor/256x256/apps
  ${super.appimage-run}/bin/appimage-run $out/opt/AppName.AppImage --appimage-extract usr/share/icons/hicolor/256x256/apps/appname.png
  cp squashfs-root/usr/share/icons/hicolor/256x256/apps/appname.png \
    $out/share/icons/hicolor/256x256/apps/

  # Use custom icon in desktop file
  Icon=$out/share/icons/hicolor/256x256/apps/appname.png
'';
```

## Example: Handy Speech-to-Text

Here's the complete overlay for Handy as a reference:

```nix
self: super: {
  handy = super.stdenv.mkDerivation rec {
    pname = "handy";
    version = "0.7.0";

    src = super.fetchurl {
      url = "https://github.com/cjpais/Handy/releases/download/v0.7.0/Handy_0.7.0_amd64.AppImage";
      sha256 = "sha256-tTswFYLCPGtMbHAb2bQMsklRiRCVXLrtu4pQC8IHdqQ=";
    };

    dontUnpack = true;
    nativeBuildInputs = [ super.makeWrapper ];
    buildInputs = [ super.appimage-run ];

    installPhase = ''
      mkdir -p $out/opt
      cp $src $out/opt/Handy.AppImage
      chmod +x $out/opt/Handy.AppImage

      mkdir -p $out/bin
      cat > $out/bin/handy <<EOF
      #!${super.stdenv.shell}
      exec ${super.appimage-run}/bin/appimage-run $out/opt/Handy.AppImage "$@"
      EOF
      chmod +x $out/bin/handy

      mkdir -p $out/share/applications
      cat > $out/share/applications/handy.desktop <<EOF
      [Desktop Entry]
      Name=Handy
      Comment=Offline speech-to-text application
      Exec=$out/bin/handy
      Icon=audio-input-microphone
      Terminal=false
      Type=Application
      Categories=AudioVideo;Audio;Recorder;Utility;
      Keywords=speech;transcription;stt;voice;dictation;
      StartupWMClass=Handy
      EOF
    '';

    meta = with super.lib; {
      description = "A free, open source, and extensible speech-to-text application that works completely offline.";
      homepage = "https://github.com/cjpais/Handy";
      license = licenses.mit;
      platforms = platforms.linux;
      maintainers = with maintainers; [ ];
    };
  };
}
```

## Troubleshooting

### Application doesn't appear in launcher

1. Verify the desktop file is installed:
   ```bash
   ls /run/current-system/sw/share/applications/ | grep appname
   ```

2. Check the desktop file syntax:
   ```bash
   desktop-file-validate /run/current-system/sw/share/applications/appname.desktop
   ```

3. Log out and log back in to refresh the desktop database

### AppImage won't run

1. Check if `appimage-run` is working:
   ```bash
   appimage-run --version
   ```

2. Test running the AppImage directly:
   ```bash
   appimage-run /nix/store/.../AppName.AppImage
   ```

3. Check for missing dependencies in error messages

### Flake evaluation errors

1. Ensure all modified files are staged in git:
   ```bash
   git add overlays/appname.nix flake.nix hosts/hostname/packages.nix
   ```

2. Check for syntax errors in your overlay:
   ```bash
   nix eval .#nixosConfigurations.hostname.config.system.build.toplevel
   ```

## Additional Resources

- [NixOS Manual - Overlays](https://nixos.org/manual/nixpkgs/stable/#chap-overlays)
- [AppImage Documentation](https://docs.appimage.org/)
- [Desktop Entry Specification](https://specifications.freedesktop.org/desktop-entry-spec/latest/)
- [Icon Theme Specification](https://specifications.freedesktop.org/icon-theme-spec/latest/)
