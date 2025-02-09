{ config, lib, ... }:

with lib;

let cfg = config.modules.template;

in {
  imports = [ ./core/security.nix ];

  options.modules.template = {
    desktop = mkEnableOption "Enable desktop mode";
    headless = mkEnableOption "Enable headless mode";
  };

  config = {

    assertions = [{
      assertion = cfg.desktop != cfg.headless;
      message =
        "Either desktop mode or headless mode must be enabled, but not both.";
    }];

    # Timezone & locale
    time.timeZone = "Europe/Sofia";
    i18n.defaultLocale = "en_US.UTF-8";
    i18n.extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
  };
}
