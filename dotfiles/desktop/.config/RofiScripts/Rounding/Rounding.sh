#!/bin/sh

chosen=$(printf "Pointy (0px)\nSoft Round (10px)\nRound (20px)\n" | rofi -dmenu -i -config '~/.config/RofiScripts/Rounding/R.rasi')

case "$chosen" in
   "Pointy (0px)") ~/.config/RofiScripts/Rounding/RoundingThemes/0px/pointy.sh ;;
   "Soft Round (10px)") ~/.config/RofiScripts/Rounding/RoundingThemes/10px/softround.sh ;;
   "Round (20px)") ~/.config/RofiScripts/Rounding/RoundingThemes/20px/round.sh ;;
   *) exit 1 ;;
esac
