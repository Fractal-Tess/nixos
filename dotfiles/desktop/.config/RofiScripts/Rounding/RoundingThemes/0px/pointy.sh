#!/bin/sh

ln -sf ~/.config/RofiScripts/Rounding/RoundingThemes/0px/hyprdecoration.lua ~/.config/hypr/hyprconfigs/hyprdecoration.lua
ln -sf ~/.config/RofiScripts/Rounding/RoundingThemes/0px/rofiradius.rasi ~/.config/colors/rofiradius.rasi
ln -sf ~/.config/RofiScripts/Rounding/RoundingThemes/0px/swayncradius.css ~/.config/colors/swayncradius.css
hyprctl reload
swaync-client -R
swaync-client -rs
notify-send "Rounding" "Pointy (0px) applied"
