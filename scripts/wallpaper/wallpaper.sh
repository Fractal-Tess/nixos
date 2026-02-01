#!/usr/bin/env bash

# Wallpaper dispatcher - reads WALLPAPER_TYPE env var and delegates to appropriate script
# Valid types: LINUX_WALLPAPERENGINE (default), WAYPAPER

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TYPE="${WALLPAPER_TYPE:-WAYPAPER}"

case "$TYPE" in
    WAYPAPER)
        exec "${SCRIPT_DIR}/waypaper.sh" "$@"
        ;;
    LINUX_WALLPAPERENGINE)
        exec "${SCRIPT_DIR}/linux_wallpaperengine.sh" "$@"
        ;;
    *)
        echo "Error: Invalid WALLPAPER_TYPE='$TYPE'. Use WAYPAPER or LINUX_WALLPAPERENGINE" >&2
        exit 1
        ;;
esac
