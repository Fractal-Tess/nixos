{ osConfig, lib, ... }:

with lib;

let
  waybarConfig = if osConfig.networking.hostName == "kiwi" then
    ./config-kiwi.jsonc
  else
    ./config-vd.jsonc;
in
{
  # Waybar (host-specific config.jsonc, shared style.css)
  xdg.configFile."waybar/config.jsonc" =
    mkIf osConfig.modules.display.waybar.enable { source = waybarConfig; };
  xdg.configFile."waybar/style.css" =
    mkIf osConfig.modules.display.waybar.enable {
      source = ./style.css;
    };
}