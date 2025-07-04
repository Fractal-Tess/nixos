# SMB/CIFS Mount Module for NixOS

This module provides support for mounting SMB/CIFS (Windows/Samba) network shares on NixOS hosts.

## Features

- Declarative configuration of SMB/CIFS shares to be mounted at boot
- Systemd-based automount for on-demand mounting
- Per-share credentials and mount options (including credentials file support)

## Usage Example

In your host configuration (e.g., `/host/<host>/configuration`):

```nix
modules.filesystems.smb = {
  enable = true;
  shares = [
    {
      mountPoint = "/mnt/share";
      device = "//server/share";
      credentialsFile = "/etc/nixos/smb-secrets"; # Use a credentials file (recommended)
      uid = 1000;
      gid = 100;
    }
  ];
};
```

Example contents of `/etc/nixos/smb-secrets`:

```
username=myuser
password=mypassword
```

Alternatively, you can use inline username/password (not recommended):

```nix
modules.filesystems.smb = {
  enable = true;
  shares = [
    {
      mountPoint = "/mnt/share";
      device = "//server/share";
      username = "user";
      password = "pass";
      uid = 1000;
      gid = 100;
    }
  ];
};
```

## Security Note

- Storing passwords in Nix configs is **not secure**. Using a credentials file is recommended for production systems.
- Ensure the credentials file is only readable by trusted users.

## Options

- `enable` (boolean): Enable SMB/CIFS share mounting.
- `shares` (list): List of share definitions. Each entry defines a share to be mounted.
  - `mountPoint` (string): Where to mount the share. Example: `/mnt/share`.
  - `device` (string): UNC path to the share. Example: `//server/share`.
  - `username` (string): SMB username. Ignored if `credentialsFile` is set.
  - `password` (string): SMB password. Ignored if `credentialsFile` is set.
  - `credentialsFile` (string, optional): Path to a file containing SMB credentials in the format:
    ```
    username=USER
    password=PASS
    ```
    If set, this file will be used for authentication instead of `username`/`password` options.
  - `uid` (int, default: 1000): Local user ID for file ownership (default: 1000, typically the first user account).
  - `gid` (int, default: 100): Local group ID for file ownership (default: 100, typically the "users" group).

**Precedence:**

- If `credentialsFile` is set, it is used for authentication.
- If not set, `username` and `password` options are used.

## How it works

This module will mount the specified SMB shares at boot using systemd automount. Each share is configured as a NixOS `fileSystems` entry with appropriate mount options for SMB/CIFS.
