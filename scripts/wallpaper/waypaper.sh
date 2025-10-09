#!/usr/bin/env bash

# Waypaper launcher

set -euo pipefail

command -v waypaper &>/dev/null || { echo "waypaper not found" >&2; exit 1; }

exec waypaper --restore "$@"

