#!/bin/sh

ln -sf ~/.config/RofiScripts/Rounding/RoundingThemes/0px/hyprdecoration.conf ~/.config/hypr/hyprconfigs/hyprdecoration.conf
ln -sf ~/.config/RofiScripts/Rounding/RoundingThemes/0px/rofiradius.rasi ~/.config/colors/rofiradius.rasi
ln -sf ~/.config/RofiScripts/Rounding/RoundingThemes/0px/swayncradius.css ~/.config/colors/swayncradius.css
hyprctl reload
swaync-client -R
swaync-client -rs
notify-send "Rounding" "Pointy (0px) applied"
