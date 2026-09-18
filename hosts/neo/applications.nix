{
  config,
  inputs,
  lib,
  ...
}:

{
  imports = [
    inputs.scorch.nixosModules.default
    inputs.gitadel.nixosModules.default
    inputs.gitadel.nixosModules.gitadel-cli
    inputs.oh-my-pi-flake.nixosModules.default
  ];

  #============================================================================
  # APPLICATION DEFAULTS
  #============================================================================

  programs.omp.enable = lib.mkDefault true;
  programs.scorch.enable = lib.mkDefault true;
  programs.gitadel-cli = {
    enable = lib.mkDefault true;
    serverUrl = lib.mkDefault "http://neo.netbird.cloud:3030";
    tokenFile = config.sops.secrets.gitadel_api_token.path;
  };

  services.scorchd = {
    enable = lib.mkDefault true;
    address = lib.mkDefault "0.0.0.0";
  };

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
    "d /mnt/blockade/services/gitadel-backups 0750 gitadel gitadel -"
  ];

  systemd.services.gitadel.serviceConfig.ReadWritePaths = [
    "/mnt/blockade/services/gitadel"
    "/mnt/blockade/services/gitadel-backups"
  ];

  networking.firewall.interfaces.wt0.allowedTCPPorts = [
    3030
    2222
  ];
}
