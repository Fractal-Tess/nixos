{
  config,
  lib,
  pkgs,
  username,
  ...
}:

with lib;

let
  cfg = config.modules.services.hermes-agent;
in
{
  #============================================================================
  # OPTIONS
  #============================================================================
  options.modules.services.hermes-agent = {
    enable = mkEnableOption "Hermes Agent";

    baseUrl = mkOption {
      type = types.str;
      default = "http://127.0.0.1:8080/v1";
      description = "OpenAI-compatible inference endpoint used by Hermes Agent.";
    };

    container = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Run Hermes in the upstream persistent container mode.";
      };
    };

    model = mkOption {
      type = types.str;
      default = "hermes-local";
      description = "Default model name for Hermes Agent.";
    };

    contextLength = mkOption {
      type = types.int;
      default = 65536;
      description = "Context length advertised to Hermes for the default model.";
    };
  };

  #============================================================================
  # CONFIG
  #============================================================================
  config = mkIf cfg.enable {
    users.groups.hermes.members = [ username ];

    services.hermes-agent = {
      enable = true;
      addToSystemPackages = true;
      createUser = false;
      group = username;
      user = username;
      workingDirectory = "/home/${username}";

      settings = {
        model = {
          base_url = cfg.baseUrl;
          context_length = cfg.contextLength;
          default = cfg.model;
        };
        toolsets = [ "all" ];
        terminal = {
          backend = "local";
          cwd = "/home/${username}";
          timeout = 180;
        };
        memory = {
          memory_enabled = true;
          user_profile_enabled = true;
        };
      };

      environment.OPENAI_API_KEY = "local";

      container = {
        enable = cfg.container.enable;
        backend = "docker";
        hostUsers = [ username ];
        extraVolumes = [
          "/home/${username}/dev:/projects:rw"
          "/home/${username}/nixos:/nixos:rw"
        ];
      };

      extraPackages = with pkgs; [
        git
        ripgrep
        fd
        curl
        jq
        nodejs
      ];
    };

    systemd.tmpfiles.rules = [
      "z /var/lib/hermes 0770 ${username} ${username} -"
      "Z /var/lib/hermes/.hermes 0770 ${username} ${username} -"
      "L+ /var/lib/hermes/dev - - - - /home/${username}/dev"
    ];
  };
}
