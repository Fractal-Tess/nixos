{ pkgs, ... }:
{
  virtualisation.oci-containers.containers.rustfs-redundant = {
    image = "rustfs/rustfs@sha256:ed9210d6411d77ffceb70d94b964a3cb7d225983368bc25bebe01e995293dcc2";
    environmentFiles = [ "/var/lib/rustfs/environment" ];
    environment = {
      RUSTFS_ADDRESS = "0.0.0.0:9000";
      RUSTFS_CONSOLE_ADDRESS = "0.0.0.0:9001";
      RUSTFS_CONSOLE_ENABLE = "true";
      RUSTFS_STORAGE_CLASS_STANDARD = "EC:1";
      RUSTFS_STORAGE_CLASS_RRS = "EC:1";
      RUSTFS_ERASURE_SET_DRIVE_COUNT = "2";
      RUSTFS_CORS_ALLOWED_ORIGINS = "*";
      RUSTFS_CONSOLE_CORS_ALLOWED_ORIGINS = "*";
    };
    ports = [
      "127.0.0.1:19000:9000"
      "127.0.0.1:19001:9001"
    ];
    volumes = [
      "/mnt/blockade/services/rustfs-redundant:/data1"
      "/mnt/vault/services/rustfs-redundant:/data2"
    ];
    cmd = [ "/data{1...2}" ];
  };
  systemd.services.docker-rustfs-redundant.unitConfig.RequiresMountsFor = [
    "/mnt/blockade"
    "/mnt/vault"
  ];
  systemd.services.rustfs-migrate-redundant = {
    description = "Migrate and verify objects into two-disk RustFS pool";
    requires = [
      "docker-rustfs.service"
      "docker-rustfs-redundant.service"
    ];
    after = [
      "docker-rustfs.service"
      "docker-rustfs-redundant.service"
    ];
    unitConfig.RequiresMountsFor = [
      "/mnt/blockade"
      "/mnt/vault"
    ];
    path = [
      pkgs.rclone
      pkgs.curl
      pkgs.coreutils
    ];
    serviceConfig = {
      Type = "oneshot";
      EnvironmentFile = "/var/lib/rustfs/environment";
      StateDirectory = "rustfs-migration";
      StateDirectoryMode = "0700";
      UMask = "0077";
      TimeoutStartSec = "12h";
      Nice = 10;
    };
    script = ''
      set -euo pipefail
      export RCLONE_CONFIG=/dev/null
      for remote in SOURCE TARGET; do
        export "RCLONE_CONFIG_''${remote}_TYPE=s3"
        export "RCLONE_CONFIG_''${remote}_PROVIDER=Other"
        export "RCLONE_CONFIG_''${remote}_REGION=us-east-1"
        export "RCLONE_CONFIG_''${remote}_FORCE_PATH_STYLE=true"
        export "RCLONE_CONFIG_''${remote}_ACCESS_KEY_ID=$RUSTFS_ACCESS_KEY"
        export "RCLONE_CONFIG_''${remote}_SECRET_ACCESS_KEY=$RUSTFS_SECRET_KEY"
      done
      export RCLONE_CONFIG_SOURCE_ENDPOINT=http://127.0.0.1:9000
      export RCLONE_CONFIG_TARGET_ENDPOINT=http://127.0.0.1:19000
      for port in 9000 19000; do
        curl --fail --silent --show-error --retry 30 --retry-delay 2 --retry-connrefused \
          "http://127.0.0.1:$port/health/ready" > /dev/null
      done
      rclone lsjson source: --recursive --files-only --hash > /var/lib/rustfs-migration/source-before.json
      rclone lsjson source: --dirs-only > /var/lib/rustfs-migration/buckets.json
      printf 'user = "%s:%s"\n' "$RUSTFS_ACCESS_KEY" "$RUSTFS_SECRET_KEY" |
        curl --fail --silent --show-error --config - --aws-sigv4 aws:amz:us-east-1:s3 \
          http://127.0.0.1:9000/rustfs/admin/v3/export-iam -o /var/lib/rustfs-migration/iam.zip
      rclone copy source: target: --create-empty-src-dirs --metadata \
        --transfers 2 --checkers 2 --stats 30s --stats-one-line --log-level INFO
      rclone check source: target: --download --one-way --checkers 2 \
        --stats 30s --stats-one-line --log-level INFO
      rclone lsjson source: --recursive --files-only --hash > /var/lib/rustfs-migration/source-after.json
      printf 'user = "%s:%s"\n' "$RUSTFS_ACCESS_KEY" "$RUSTFS_SECRET_KEY" |
        curl --fail --silent --show-error --config - --aws-sigv4 aws:amz:us-east-1:s3 \
          -X PUT -H 'Content-Type: application/zip' --data-binary @/var/lib/rustfs-migration/iam.zip \
          http://127.0.0.1:19000/rustfs/admin/v3/import-iam > /var/lib/rustfs-migration/iam-import-result.json
      date -u +%FT%TZ > /var/lib/rustfs-migration/copy-verified
    '';
  };
}
