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

    provider = mkOption {
      type = types.str;
      default = "openrouter";
      description = "Provider name for Hermes Agent (e.g., openrouter, opencode-go, opencode-zen).";
    };

    contextLength = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = "Optional context length advertised to Hermes for the default model.";
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
         model =
           {
             base_url = cfg.baseUrl;
             default = cfg.model;
             provider = cfg.provider;
           }
           // optionalAttrs (cfg.contextLength != null) {
             context_length = cfg.contextLength;
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
      }
      // optionalAttrs config.modules.services.firecrawl.enable {
        web = {
          search_backend = "firecrawl";
          extract_backend = "firecrawl";
        };
      };

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
        github-mcp-server
      ];
    };

    systemd.tmpfiles.rules = [
      "z /var/lib/hermes 0770 ${username} ${username} -"
      "Z /var/lib/hermes/.hermes 0770 ${username} ${username} -"
      "L+ /var/lib/hermes/dev - - - - /home/${username}/dev"
    ];
  };
}
