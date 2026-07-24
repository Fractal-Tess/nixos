{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.modules.services.nessus;

  fhsPackages =
    pkgs': with pkgs'; [
      bash
      coreutils
      glibc
      hostname
      iproute2
      openssl
      procps
      zlib
    ];

  fhsProfile = ''
    export LD_LIBRARY_PATH="${cfg.installPath}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    export NESSUS_TZ_DIR=/etc/zoneinfo
  '';

  nessusFhs = pkgs.buildFHSEnv {
    name = "nessus";
    targetPkgs = fhsPackages;
    profile = fhsProfile;
    runScript = "${cfg.installPath}/sbin/nessusd";
  };

  nessusCliFhs = pkgs.buildFHSEnv {
    name = "nessus-cli";
    targetPkgs = fhsPackages;
    profile = fhsProfile;
    runScript = "${cfg.installPath}/sbin/nessuscli";
  };
in
{
  #============================================================================
  # OPTIONS
  #============================================================================
  options.modules.services.nessus = {
    enable = mkEnableOption "Tenable Nessus vulnerability scanner";

    installPath = mkOption {
      type = types.str;
      default = "/opt/nessus";
      description = "Mutable Nessus installation extracted from the official Tenable package";
    };

    port = mkOption {
      type = types.port;
      default = 8834;
      description = "HTTPS port configured in Nessus and optionally opened by this module";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Open the Nessus web interface port to the network";
    };
  };

  #============================================================================
  # CONFIG
  #============================================================================
  config = mkIf cfg.enable {
    environment.systemPackages = [
      nessusFhs
      nessusCliFhs
      pkgs.dpkg
    ];

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];

    systemd.services.nessusd = {
      description = "Tenable Nessus vulnerability scanner";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      unitConfig.ConditionFileIsExecutable = "${cfg.installPath}/sbin/nessusd";

      serviceConfig = {
        Type = "simple";
        ExecStart = "${nessusFhs}/bin/nessus -q";
        Restart = "always";
        RestartSec = "5s";
        User = "root";
        Group = "root";
        LimitNOFILE = 65536;
        PrivateTmp = false;
        ProtectHome = false;
        ProtectSystem = false;
      };
    };
  };
}
