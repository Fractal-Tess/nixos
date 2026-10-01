{
  config,
  inputs,
  lib,
  pkgs,
  username,
  ...
}:

{
  imports = [
    inputs.gitadel.nixosModules.default
    inputs.gitadel.nixosModules.gitadel-cli
    inputs.immich-flake.nixosModules.default
    inputs.oh-my-pi-flake.nixosModules.default
    inputs.claude-code-flake.nixosModules.default
    inputs.codex-flake.nixosModules.default
    inputs.opencode-flake.nixosModules.default
  ];

  config = lib.mkMerge [
    # OMP
    {
      programs.omp.enable = lib.mkDefault true;
    }

    # Claude Code
    {
      programs.claude-code.enable = true;
    }

    # Codex
    {
      programs.codex.enable = true;
    }

    # opencode
    {
      programs.opencode.enable = true;
    }

    # ClipSync
    {
      home-manager.users.${username}.services.clip-sync = {
        enable = true;
        configFile = ./clip-sync.toml;
        wantedBy = [ "default.target" ];
      };
      sops.secrets.clip_sync_mesh_key = {
        sopsFile = ../../secrets/clip-sync.json;
        format = "json";
        owner = username;
        group = "users";
        mode = "0400";
      };
    }

    # Immich
    {
      services.immich = {
        enable = true;
        host = "0.0.0.0";
        openFirewall = true;
        # Existing library, previously bind-mounted into the Dokploy container
        mediaLocation = "/mnt/blockade/services/neo-immich-egyjka/uploads";
        # VA-API transcoding on the AMD iGPU
        accelerationDevices = [ "/dev/dri/renderD128" ];
      };
      users.users.immich.extraGroups = [
        "video"
        "render"
      ];
      # Database was restored into PostgreSQL 17; keep it pinned
      services.postgresql.package = pkgs.postgresql_17;
    }

    # Gitadel
    {
      programs.gitadel-cli = {
        enable = lib.mkDefault true;
        serverUrl = lib.mkDefault "http://neo.netbird.cloud:3030";
        tokenFile = config.sops.secrets.gitadel_api_token.path;
      };
      sops.secrets.gitadel_api_token = lib.mkIf config.modules.services.sops.enable {
        owner = username;
        group = "users";
        mode = "0600";
        sopsFile = ../../secrets/gitadel.json;
        format = "json";
      };
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
      systemd.tmpfiles.rules = [
        "d /mnt/blockade/services/gitadel 0750 gitadel gitadel -"
        "d /mnt/blockade/services/gitadel-backups 0750 gitadel gitadel -"
      ];
      # ProtectSystem=strict requires explicit write access outside /var/lib/gitadel.
      systemd.services.gitadel.serviceConfig.ReadWritePaths = [
        "/mnt/blockade/services/gitadel"
        "/mnt/blockade/services/gitadel-backups"
      ];
      networking.firewall.interfaces.wt0.allowedTCPPorts = [
        3030
        2222
      ];
    }
  ];
}
