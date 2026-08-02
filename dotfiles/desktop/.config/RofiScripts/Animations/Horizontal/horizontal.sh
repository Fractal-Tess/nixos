#!/bin/sh

ln -sf ~/.config/RofiScripts/Animations/Horizontal/hypranimations.lua ~/.config/hypr/hyprconfigs/hypranimations.lua
hyprctl reload
notify-send "Animations" "Horizontal slide applied"
