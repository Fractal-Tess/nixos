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
    inputs.scorch.nixosModules.default
    inputs.gitadel.nixosModules.gitadel-cli
    inputs.oh-my-pi-flake.nixosModules.default
    inputs.responsively-flake.nixosModules.default
    inputs.t3code-flake.nixosModules.default
    inputs.delta-flake.nixosModules.default
    inputs.agent-browser-flake.nixosModules.default
  ];

  config = lib.mkMerge [
    # OMP
    {
      programs.omp.enable = lib.mkDefault true;
    }

    # Responsively
    {
      programs.responsively.enable = true;
    }

    # T3 Code
    {
      programs.t3code.enable = true;
    }

    # Delta
    {
      programs.delta.enable = true;
    }

    # Agent Browser
    {
      programs.agent-browser.enable = true;
    }

    # Scorch
    {
      programs.scorch.enable = lib.mkDefault true;
      services.scorchd = {
        enable = lib.mkDefault true;
        address = lib.mkDefault "0.0.0.0";
      };
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
    }

    # ClipSync
    {
      home-manager.users.${username}.services.clip-sync.enable = true;
      sops.secrets.clip_sync_mesh_key = {
        sopsFile = ../../secrets/clip-sync.json;
        format = "json";
        owner = username;
        group = "users";
        mode = "0400";
      };
    }

    # Shadoword
    {
      home-manager.users.${username}.services.shadoword-desktop = {
        enable = true;
        environment = {
          PATH = "/run/current-system/sw/bin:/etc/profiles/per-user/${username}/bin:/run/wrappers/bin";
          # Preserve this compositor's working WebKit backend.
          GDK_BACKEND = "x11";
          WEBKIT_DISABLE_DMABUF_RENDERER = "1";
        };
      };
      systemd.tmpfiles.rules = [
        "d /home/${username}/.config/shadoword 0700 ${username} users -"
      ];
      environment.systemPackages = [
        pkgs.wtype
        pkgs.xdotool
      ];
    }
  ];
}
