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
    inputs.gitadel.nixosModules.gitadel-cli
    inputs.claude-code-flake.nixosModules.default
    inputs.codex-flake.nixosModules.default
  ];

  config = lib.mkMerge [
    # Fader: mesh of vd, neo and kiwi; each controls the others
    {
      modules.services.fader.enable = true;
    }

    # T3 Code
    {
      modules.services.t3code-server.enable = true;
    }

    # Claude Code
    {
      programs.claude-code.enable = true;
    }

    # Codex
    {
      programs.codex.enable = true;
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

    # Gitadel client; the server moved to vd.
    {
      programs.gitadel-cli = {
        enable = lib.mkDefault true;
        serverUrl = lib.mkDefault "http://vd.netbird.cloud:3030";
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
  ];
}
