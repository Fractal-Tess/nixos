#!/usr/bin/env bash

# Waybar toggle script
# Toggles waybar visibility by showing/hiding it

set -euo pipefail

# Check if waybar is running
if pgrep -x "waybar" > /dev/null; then
    # Waybar is running, toggle visibility
    if pgrep -f "waybar.*--hidden" > /dev/null; then
        # Waybar is hidden, show it
        pkill -f "waybar.*--hidden"
        waybar &
        notify-send "Waybar" "🟢 Shown" -h string:x-canonical-private-synchronous:waybar-status
    else
        # Waybar is visible, hide it
        pkill waybar
        waybar --hidden &
        notify-send "Waybar" "🔴 Hidden" -h string:x-canonical-private-synchronous:waybar-status
    fi
else
    # Waybar is not running, start it
    waybar &
    notify-send "Waybar" "🟢 Started" -h string:x-canonical-private-synchronous:waybar-status
fi
