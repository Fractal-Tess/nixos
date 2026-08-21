{
  inputs,
  pkgs,
  ...
}:

{
  #============================================================================
  # GITADEL ARCHIVE SERVER
  #============================================================================

  services.gitadel = {
    enable = true;
    package = inputs.gitadel.packages.${pkgs.stdenv.hostPlatform.system}.default;
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

  networking.firewall.interfaces.wt0.allowedTCPPorts = [
    3030
    2222
  ];
}
