#!/bin/sh

ln -sf ~/.config/RofiScripts/Animations/Horizontal/hypranimations.conf ~/.config/hypr/hyprconfigs/hypranimations.conf
hyprctl reload
notify-send "Animations" "Horizontal slide applied"
