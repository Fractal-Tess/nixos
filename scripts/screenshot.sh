#!/usr/bin/env bash

# Create the screenshots directory if it doesn't exist
mkdir -p ~/Pictures/screenshots

# Generate the filename with timestamp
filename=~/Pictures/screenshots/screenshot_$(date +%Y%m%d_%H%M%S).png

# Take the screenshot and save it
grim -g "$(slurp)" "$filename"

# Copy the saved image to clipboard
wl-copy < "$filename"

# Notify the user
notify-send "Screenshot saved" "File: $filename"
