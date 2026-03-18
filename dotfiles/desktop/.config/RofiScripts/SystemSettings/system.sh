#!/bin/sh

chosen=$(printf "󱄅 Hyprland Reload\n NixOS Rebuild\n" | rofi -dmenu -i -config '~/.config/RofiScripts/SystemSettings/S.rasi')

case "$chosen" in
   "󱄅 Hyprland Reload") hyprctl reload && notify-send "Hyprland" "Config reloaded" ;;
   " NixOS Rebuild") ~/.config/RofiScripts/SystemSettings/nixos.sh ;;
   *) exit 1 ;;
esac
