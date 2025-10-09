#!/usr/bin/env bash

# Wallpaper dispatcher - reads WALLPAPER_TYPE env var and delegates to appropriate script
# Valid types: LINUX_WALLPAPERENGINE (default), WAYPAPER

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TYPE="${WALLPAPER_TYPE:-LINUX_WALLPAPERENGINE}"

case "$TYPE" in
    LINUX_WALLPAPERENGINE)
        exec "${SCRIPT_DIR}/linux_wallpaperengine.sh" "$@"
        ;;
    WAYPAPER)
        exec "${SCRIPT_DIR}/waypaper.sh" "$@"
        ;;
    *)
        echo "Error: Invalid WALLPAPER_TYPE='$TYPE'. Use LINUX_WALLPAPERENGINE or WAYPAPER" >&2
        exit 1
        ;;
esac
