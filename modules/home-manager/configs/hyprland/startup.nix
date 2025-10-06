{ ... }:

{
  startup = ''
    # Start once
    exec-once = /home/fractal-tess/nixos/scripts/linux-wallpaperengine/wallpaper.sh
    exec-once = hyprctl setcursor Nordzy-cursors 24
    exec-once = wl-paste --watch cliphist store
    exec-once = blueman-applet
    exec-once = nm-applet
    exec-once = netbird-ui
    exec-once = hypridle
  '';
}
