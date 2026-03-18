#!/bin/sh

ln -sf ~/.config/RofiScripts/Rounding/RoundingThemes/10px/hyprdecoration.conf ~/.config/hypr/hyprconfigs/hyprdecoration.conf
ln -sf ~/.config/RofiScripts/Rounding/RoundingThemes/10px/rofiradius.rasi ~/.config/colors/rofiradius.rasi
ln -sf ~/.config/RofiScripts/Rounding/RoundingThemes/10px/swayncradius.css ~/.config/colors/swayncradius.css
hyprctl reload
swaync-client -R
swaync-client -rs
notify-send "Rounding" "Soft Round (10px) applied"
