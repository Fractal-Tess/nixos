# Samba share and mount

`share.nix` (server) and `mount.nix` (client) share directories between hosts
over NetBird without ever changing the owner, mode or ACL of an existing file.

## How permissions stay intact

- Clients log in as `fractal-tess` (password from `secrets/samba.json`). There
  is no `force user`/`force group`: smbd runs as that user, so the server's
  kernel decides access exactly as if you were working on it over SSH.
  Files owned by other users (gitadel, vaultwarden, root, containers with
  other uids) cannot be modified, chmodded or chowned.
- `nt acl support = no`, `smb3 unix extensions = no`: a client has no way to
  send a chmod, chown or ACL change. `chmod` on a client succeeds locally and
  does nothing on the server.
- `store dos attributes = yes` with all `map *` off: DOS attributes
  (read-only, hidden, archive) go into a `user.DOSATTRIB` xattr instead of
  being emulated with chmod. That xattr appears on files created or written
  through the share; reading never adds it.
- `inherit permissions = yes`: new files copy the parent directory's mode
  (minus execute) and ACL. New files are owned `fractal-tess:users`.
- On the client every file shows as `uid`/`gid` with `fileMode`/`dirMode`.
  That is display only; the server still enforces the real permissions.

Port 445 is opened on `wt0` only and smbd accepts only `100.91.0.0/16`.

## Usage

```nix
# server (neo)
modules.services.samba.share = {
  enable = true;
  shares.blockade.path = "/mnt/blockade";
};

# client (vd, kiwi)
modules.services.samba.mount = {
  enable = true;
  mounts."/mnt/blockade".device = "//neo.netbird.cloud/blockade";
};
```

Mounts happen on first access and unmount after 10 minutes idle. They never
block boot when the server is offline.

Do not put `systemd.tmpfiles` rules on a client's mount point. With these
settings they cannot change the server, but they are pointless and would
be dangerous with any other mount type.
