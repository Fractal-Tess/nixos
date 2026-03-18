#!/bin/sh

ln -sf ~/.config/RofiScripts/Animations/Vertical/hypranimations.conf ~/.config/hypr/hyprconfigs/hypranimations.conf
hyprctl reload
notify-send "Animations" "Vertical slide applied"
