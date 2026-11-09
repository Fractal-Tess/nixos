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

Shares are listed once in `fleet.nix` (`modules.services.samba.fleet.hosts`):

| Host | Shares |
| --- | --- |
| neo | `home` (/home/fractal-tess) |
| vd | `vault` (/mnt/vault), `blockade` (/mnt/blockade), `home` (/home/fractal-tess) |

Every host with `modules.services.samba.fleet.enable = true` exports its own
entries and mounts every other host's at `/mnt/<host>/<share>`, e.g.
`/mnt/vd/blockade` and `/mnt/vd/vault`. kiwi only mounts.

## Offline hosts

Shares are never mounted on access. `samba-mount-watch.timer` runs every 20s
(`mount.checkInterval`) and tests each host's port 445:

- reachable and not mounted: mount it
- mounted and unreachable for 3 checks in a row (`mount.missesBeforeDetach`):
  lazily detach it, so the directory shows empty instead of hanging

A host that is offline therefore never blocks a file manager, and it is
mounted again within one check after it comes back. If a host dies while a
share is in use, the operation in flight fails after ~30s (`soft`,
`echo_interval=10`); shorter values drop healthy sessions on slow uplinks.
