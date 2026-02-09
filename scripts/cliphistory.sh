#!/usr/bin/env bash
# If wofi is already running, kill it
pkill wofi

# Get the clipboard history, display it in wofi, and copy the selected item to the clipboard
cliphist list | wofi -dmenu -p "Clipboard:" | cliphist decode | wl-copy
