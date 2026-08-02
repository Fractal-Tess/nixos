#!/bin/sh

ln -sf ~/.config/RofiScripts/Rounding/RoundingThemes/20px/hyprdecoration.lua ~/.config/hypr/hyprconfigs/hyprdecoration.lua
ln -sf ~/.config/RofiScripts/Rounding/RoundingThemes/20px/rofiradius.rasi ~/.config/colors/rofiradius.rasi
ln -sf ~/.config/RofiScripts/Rounding/RoundingThemes/20px/swayncradius.css ~/.config/colors/swayncradius.css
hyprctl reload
swaync-client -R
swaync-client -rs
notify-send "Rounding" "Round (20px) applied"
