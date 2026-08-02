#!/bin/sh

ln -sf ~/.config/RofiScripts/Animations/Vertical/hypranimations.lua ~/.config/hypr/hyprconfigs/hypranimations.lua
hyprctl reload
notify-send "Animations" "Vertical slide applied"
