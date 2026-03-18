#!/bin/sh

chosen=$(printf "󰐥\n󰜉\n󰌾\n󰀄" | rofi -dmenu -i -config '~/.config/RofiScripts/powermenu/P.rasi')

case "$chosen" in
   "󰐥") systemctl poweroff ;;
   "󰜉") systemctl reboot ;;
   "󰌾") hyprlock ;;
   "󰀄") hyprctl dispatch exit ;;
   *) exit 1 ;;
esac
