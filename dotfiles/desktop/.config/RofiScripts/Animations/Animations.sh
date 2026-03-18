#!/bin/sh

chosen=$(printf "Horizontal Slide\nVertical Slide\n" | rofi -dmenu -i -config '~/.config/RofiScripts/Animations/A.rasi')

case "$chosen" in
   "Horizontal Slide") ~/.config/RofiScripts/Animations/Horizontal/horizontal.sh ;;
   "Vertical Slide") ~/.config/RofiScripts/Animations/Vertical/vertical.sh ;;
   *) exit 1 ;;
esac
