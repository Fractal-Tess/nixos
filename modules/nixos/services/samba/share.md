# Samba Share Server Module for NixOS

This module provides a Samba server for sharing directories over the network using the SMB/CIFS protocol.

## Features

- Export local directories as SMB/CIFS shares
- Per-share access control and configuration
- Integration with NixOS firewall and systemd

## Usage Example

In your host configuration (e.g., `/host/<host>/configuration`):

```nix
modules.services.samba-share = {
  enable = true;
  shares = [
    {
      name = "home";
      path = "/home/username";
      validUsers = [ "username" ];
      readOnly = false;
      guestOk = false;
      forceUser = "username";
      forceGroup = "users";
      createMask = "0644";
      directoryMask = "0755";
    }
  ];
};
```

## Security Note

- Ensure only trusted users have access to exported shares.
- Use strong passwords for Samba users.
- Consider restricting guest access (`guestOk = false`) for sensitive shares.

## Options

- `enable` (boolean): Enable the Samba share service.
- `shares` (list): List of share definitions. Each entry defines a share to export.
  - `name` (string): Share name (as seen by clients).
  - `path` (string): Path to the directory to share.
  - `validUsers` (list of strings): Users allowed to access the share.
  - `readOnly` (bool, default: false): If true, share is read-only.
  - `guestOk` (bool, default: false): If true, allow guest access.
  - `forceUser` (string, optional): Force all access as this user.
  - `forceGroup` (string, optional): Force all access as this group.
  - `createMask` (string, default: "0644"): File creation mask.
  - `directoryMask` (string, default: "0755"): Directory creation mask.
- `openFirewall` (bool, default: true): Open firewall ports for Samba.
- `extraGlobal` (attrs, default: `{}`): Extra global Samba settings.

## How it works

This module enables the Samba service, configures the firewall, and exports the specified shares with the given options. Each share is configured with access control, masks, and optional forced user/group settings. Global Samba settings can be extended via `extraGlobal`.
