{ pkgs, ... }:
let
  destination = "/mnt/vault/services/rustfs-recovery";
  instructions = pkgs.writeText "rustfs-recovery.txt" ''
    RustFS recovery copy (current S3 objects, not a live RustFS data directory).
    objects/<bucket>/<key> contains ordinary downloaded object files.
    buckets.json records bucket names, including empty buckets.
    iam.zip is the RustFS admin export of identities and policies.
    environment contains the root credentials. Keep this directory root-only.
    history/ preserves objects replaced by later copies. Source deletions are
    not propagated. last-success exists only after full read-back comparison.

    Recovery: create a fresh RustFS data directory on a healthy disk using the
    pinned image in hosts/vd/server.nix and the saved environment credentials.
    Recreate buckets from buckets.json; upload files from each objects/<bucket>/
    directory through S3 (rclone copy), then restore IAM using RustFS's admin
    import workflow. Configure required bucket settings separately. Test client
    credentials and read back restored objects before directing clients there.
    Never point RustFS directly at objects/: it is an S3 export, not xl.meta data.

    This is a changing current-object copy, not an atomic whole-store snapshot.
    Historical S3 versions, bucket policies, lifecycle and replication settings
    are not captured. Retained deleted objects require deliberate selection on
    restore. It provides manual disk-loss recovery, not automatic failover or
    protection against loss of the whole VD machine.
  '';
in
{
  systemd.services.rustfs-vault-backup = {
    description = "Copy and verify RustFS objects on Vault";
    requires = [ "docker-rustfs.service" ];
    after = [ "docker-rustfs.service" ];
    unitConfig.RequiresMountsFor = [
      "/mnt/blockade"
      "/mnt/vault"
    ];
    path = [
      pkgs.rclone
      pkgs.curl
      pkgs.coreutils
      pkgs.util-linux
    ];
    serviceConfig = {
      Type = "oneshot";
      EnvironmentFile = "/var/lib/rustfs/environment";
      UMask = "0077";
      Nice = 10;
      IOSchedulingClass = "idle";
      TimeoutStartSec = "12h";
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [ "/mnt/vault/services" ];
      NoNewPrivileges = true;
    };
    script = ''
      set -euo pipefail
      mountpoint -q /mnt/blockade
      mountpoint -q /mnt/vault
      install -d -m 0700 ${destination}
      export RCLONE_CONFIG=/dev/null
      export RCLONE_CONFIG_SOURCE_TYPE=s3
      export RCLONE_CONFIG_SOURCE_PROVIDER=Other
      export RCLONE_CONFIG_SOURCE_ENDPOINT=http://127.0.0.1:9000
      export RCLONE_CONFIG_SOURCE_REGION=us-east-1
      export RCLONE_CONFIG_SOURCE_FORCE_PATH_STYLE=true
      export RCLONE_CONFIG_SOURCE_ACCESS_KEY_ID="$RUSTFS_ACCESS_KEY"
      export RCLONE_CONFIG_SOURCE_SECRET_ACCESS_KEY="$RUSTFS_SECRET_KEY"
      run=$(date -u +%Y%m%dT%H%M%SZ)
      install -m 0600 ${instructions} ${destination}/RESTORE.txt
      install -m 0600 /var/lib/rustfs/environment ${destination}/environment
      printf 'user = "%s:%s"\n' "$RUSTFS_ACCESS_KEY" "$RUSTFS_SECRET_KEY" |
        curl --fail --silent --show-error --config - --aws-sigv4 aws:amz:us-east-1:s3 \
        http://127.0.0.1:9000/rustfs/admin/v3/export-iam -o ${destination}/iam.zip.new
      mv ${destination}/iam.zip.new ${destination}/iam.zip
      rclone lsjson source: --dirs-only > ${destination}/buckets.json.new
      rclone copy source: ${destination}/objects \
        --create-empty-src-dirs --backup-dir ${destination}/history/"$run" \
        --transfers 2 --checkers 2 --stats 30s --stats-one-line --log-level INFO
      rclone check source: ${destination}/objects --one-way --download \
        --checkers 2 --stats 30s --stats-one-line --log-level INFO
      mv ${destination}/buckets.json.new ${destination}/buckets.json
      date -u +%FT%TZ > ${destination}/last-success.new
      mv ${destination}/last-success.new ${destination}/last-success
    '';
  };
  systemd.timers.rustfs-vault-backup = {
    description = "Daily verified RustFS recovery copy to Vault";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 05:00:00 UTC";
      Persistent = true;
      RandomizedDelaySec = "5m";
    };
  };
}
