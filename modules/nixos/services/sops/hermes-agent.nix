{
  config,
  lib,
  username,
  ...
}:

with lib;

let
  cfg = config.modules.services.sops.hermes-agent;
in
{
  options.modules.services.sops.hermes-agent = {
    enable = mkEnableOption "Hermes Agent secrets management via SOPS";
  };

  config = mkIf (config.modules.services.sops.enable && cfg.enable) {
    sops.secrets = {
      hermes_telegram_bot_token = {
        owner = username;
        group = username;
        sopsFile = ../../../../secrets/hermes-agent.yaml;
        format = "yaml";
      };

      hermes_telegram_allowed_users = {
        owner = username;
        group = username;
        sopsFile = ../../../../secrets/hermes-agent.yaml;
        format = "yaml";
      };

      hermes_openrouter_api_key = {
        owner = username;
        group = username;
        sopsFile = ../../../../secrets/hermes-agent.yaml;
        format = "yaml";
      };
    };

    sops.templates."hermes-agent.env" = {
      owner = username;
      group = username;
      mode = "0600";
      content = ''
        OPENAI_API_KEY=${if config.modules.services.hermes-agent.provider == "openrouter" then config.sops.placeholder.hermes_openrouter_api_key else "local"}
        FIRECRAWL_API_URL=http://127.0.0.1:${toString config.modules.services.firecrawl.port}
        TELEGRAM_BOT_TOKEN=${config.sops.placeholder.hermes_telegram_bot_token}
        TELEGRAM_ALLOWED_USERS=${config.sops.placeholder.hermes_telegram_allowed_users}
      '';
    };

    services.hermes-agent.environmentFiles = [ config.sops.templates."hermes-agent.env".path ];
  };
}
