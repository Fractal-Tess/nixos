{ ... }:

{
  #============================================================================
  # GITADEL ARCHIVE SERVER
  #============================================================================

  services.gitadel = {
    enable = true;
    publicUrl = "http://neo.netbird.cloud:3030";

    http = {
      address = "0.0.0.0";
      port = 3030;
    };

    ssh = {
      address = "0.0.0.0";
      port = 2222;
    };
  };
  # Filesystem storage targets outside dataDir must be whitelisted: the unit
  # runs with ProtectSystem=strict, so anything not under /var/lib/gitadel
  # looks like a read-only filesystem (EROFS, os error 30).
  systemd.tmpfiles.rules = [
    "d /mnt/blockade/services/gitadel 0750 gitadel gitadel -"
  ];

  systemd.services.gitadel.serviceConfig.ReadWritePaths = [
    "/mnt/blockade/services/gitadel"
  ];

  networking.firewall.interfaces.wt0.allowedTCPPorts = [
    3030
    2222
  ];
}
