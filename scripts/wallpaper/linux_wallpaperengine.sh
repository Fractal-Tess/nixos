#!/usr/bin/env bash

# Linux Wallpaper Engine launcher - starts wallpaper engine on all screens
# Usage: script.sh [SCALING_MODE]  (default: fill)

set -euo pipefail

readonly SECRETS_DIR="${HOME}/.config/secrets/linux-wallpaperengine"
readonly SCALING="${1:-fill}"

# Get wallpaper ID for a screen
get_wallpaper_id() {
    cat "${SECRETS_DIR}/${1}" 2>/dev/null || cat "${SECRETS_DIR}/ANY" 2>/dev/null || return 1
}

# Kill existing processes
pkill -f "linux-wallpaperengine --screen-root" 2>/dev/null || true
sleep 0.5

# Detect screens
if command -v hyprctl &>/dev/null; then
    mapfile -t screens < <(hyprctl monitors | grep -E '^Monitor\s+' | awk '{print $2}')
else
    mapfile -t screens < <(xrandr --listactivemonitors | grep -E '^[0-9]+:' | awk '{print $4}')
fi

[[ ${#screens[@]} -eq 0 ]] && { echo "No screens detected" >&2; exit 1; }

# Start wallpaper on each screen
for screen in "${screens[@]}"; do
    if id=$(get_wallpaper_id "$screen"); then
        linux-wallpaperengine \
            --screen-root "$screen" \
            --bg "$id" \
            --scaling "$SCALING" \
            --fps 25 \
            --silent \
            --disable-mouse \
            --disable-parallax \
            >/dev/null 2>&1 &
        sleep 0.3
    fi
done

