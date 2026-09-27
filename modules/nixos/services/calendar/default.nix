{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.modules.services.calendar;

  # GObject typelibs the Waybar clock script needs to read events from
  # Evolution Data Server (the backend GNOME Calendar syncs Google into).
  typelibPath = makeSearchPath "lib/girepository-1.0" [
    pkgs.evolution-data-server
    pkgs.libical
    pkgs.libsoup_3
    pkgs.json-glib
    pkgs.glib.out
    pkgs.gobject-introspection
  ];
in
{
  #============================================================================
  # OPTIONS
  #============================================================================
  options.modules.services.calendar = {
    enable = mkEnableOption "GNOME Calendar with online account (Google) sync";
  };

  #============================================================================
  # CONFIG
  #============================================================================
  config = mkIf cfg.enable {
    # Calendar storage/sync backend and the online-accounts provider that
    # connects it to Google. Credentials live in the GNOME keyring.
    services.gnome = {
      evolution-data-server.enable = true;
      gnome-online-accounts.enable = true;
      gnome-keyring.enable = mkDefault true;
    };
    programs.dconf.enable = true;

    environment.systemPackages = with pkgs; [
      gnome-calendar
      # Standalone "Online Accounts" window, since GNOME Settings isn't installed
      gnome-online-accounts-gtk
    ];

    # Lets the Waybar clock list upcoming events in its tooltip
    systemd.user.services.waybar.environment.GI_TYPELIB_PATH = typelibPath;
  };
}
