{ lib, ... }:

with lib;

{
  config = {
    # Localization
  # Select internationalisation properties.
  i18n.defaultLocale = mkDefault "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = mkDefault "bg_BG.UTF-8";
    LC_IDENTIFICATION = mkDefault "bg_BG.UTF-8";
    LC_MEASUREMENT = mkDefault "bg_BG.UTF-8";
    LC_MONETARY = mkDefault "bg_BG.UTF-8";
    LC_NAME = mkDefault "bg_BG.UTF-8";
    LC_NUMERIC = mkDefault "bg_BG.UTF-8";
    LC_PAPER = mkDefault "bg_BG.UTF-8";
    LC_TELEPHONE = mkDefault "bg_BG.UTF-8";
    LC_TIME = mkDefault "bg_BG.UTF-8";
  };
  };
}
