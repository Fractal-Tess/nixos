{
  config,
  lib,
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
        owner = "hermes";
        group = "hermes";
        sopsFile = ../../../../secrets/hermes-agent.yaml;
        format = "yaml";
      };

      hermes_telegram_allowed_users = {
        owner = "hermes";
        group = "hermes";
        sopsFile = ../../../../secrets/hermes-agent.yaml;
        format = "yaml";
      };
    };

    sops.templates."hermes-agent.env" = {
      owner = "hermes";
      group = "hermes";
      mode = "0600";
      content = ''
        OPENAI_API_KEY=local
        TELEGRAM_BOT_TOKEN=${config.sops.placeholder.hermes_telegram_bot_token}
        TELEGRAM_ALLOWED_USERS=${config.sops.placeholder.hermes_telegram_allowed_users}
      '';
    };

    services.hermes-agent.environmentFiles = [ config.sops.templates."hermes-agent.env".path ];
  };
}
