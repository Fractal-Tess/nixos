#!/usr/bin/env bash

WAYBAR_PID=$(pgrep -x "waybar" | head -1)

if [ -n "$WAYBAR_PID" ]; then
    if tr '\0' ' ' < /proc/$WAYBAR_PID/cmdline 2>/dev/null | grep -q '\-\-hidden'; then
        kill -9 "$WAYBAR_PID" 2>/dev/null
        while kill -0 "$WAYBAR_PID" 2>/dev/null; do sleep 0.05; done
        waybar &
        notify-send "Waybar" "🟢 Shown" -h string:x-canonical-private-synchronous:waybar-status
    else
        kill -9 "$WAYBAR_PID" 2>/dev/null
        while kill -0 "$WAYBAR_PID" 2>/dev/null; do sleep 0.05; done
        waybar --hidden &
        notify-send "Waybar" "🔴 Hidden" -h string:x-canonical-private-synchronous:waybar-status
    fi
else
    waybar &
    notify-send "Waybar" "🟢 Started" -h string:x-canonical-private-synchronous:waybar-status
fi
