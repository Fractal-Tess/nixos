#!/bin/sh

chosen=$(printf " Apps\n System\n Clipboard\n Calculator\n Wallpaper\n Colorscheme\n Decorations\n Animations\n" | rofi -dmenu -i -config '~/.config/RofiScripts/Launcher/L.rasi')

case "$chosen" in
   " Apps") rofi -show drun ;;
   " System") ~/.config/RofiScripts/SystemSettings/system.sh ;;
   " Clipboard") ~/.config/RofiScripts/Clipboard/Clipboard.sh ;;
   " Calculator") ~/.config/RofiScripts/RofiCalc/Calc.sh ;;
   " Wallpaper") ~/.config/RofiScripts/WallpaperChanger/WallMenu.sh ;;
   " Colorscheme") ~/.config/RofiScripts/Dark-Light-Mode/DLmode.sh ;;
   " Decorations") ~/.config/RofiScripts/Rounding/Rounding.sh ;;
   " Animations") ~/.config/RofiScripts/Animations/Animations.sh ;;
   *) exit 1 ;;
esac
