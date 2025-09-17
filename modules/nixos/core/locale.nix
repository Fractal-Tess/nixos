{ lib, ... }:

with lib;

{
  config = {
    # Localization
    # Select internationalisation properties.
    i18n.defaultLocale = mkDefault "en_US.UTF-8";

    i18n.extraLocaleSettings = {
      LC_ADDRESS = mkDefault "en_US.UTF-8";
      LC_IDENTIFICATION = mkDefault "en_US.UTF-8";
      LC_MEASUREMENT = mkDefault "en_US.UTF-8";
      LC_MONETARY = mkDefault "en_US.UTF-8";
      LC_NAME = mkDefault "en_US.UTF-8";
      LC_NUMERIC = mkDefault "en_US.UTF-8";
      LC_PAPER = mkDefault "en_US.UTF-8";
      LC_TELEPHONE = mkDefault "en_US.UTF-8";
      LC_TIME = mkDefault "en_US.UTF-8";
    };
  };
}
