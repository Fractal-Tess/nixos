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
  };

  #============================================================================
  # CONFIG
  #============================================================================
  config = mkIf cfg.enable {
    services.hermes-agent = {
      enable = true;
      addToSystemPackages = true;

      settings = {
        model = {
          base_url = cfg.baseUrl;
          default = cfg.model;
        };
        toolsets = [ "all" ];
        terminal = {
          backend = "local";
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
      "z /var/lib/hermes 0750 hermes hermes -"
      "Z /var/lib/hermes/.hermes 0750 hermes hermes -"
    ];
  };
}
