{ ... }:

{
  startup = ''
    # Start once
    exec-once = waypaper --restore
    exec-once = hyprctl setcursor Nordzy-cursors 24
    exec-once = wl-paste --watch cliphist store
    exec-once = blueman-applet
    exec-once = nm-applet
    exec-once = netbird-ui
    exec-once = hypridle
  '';
}