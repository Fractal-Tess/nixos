#!/usr/bin/env bash

gpu_busy=/sys/class/drm/card1/device/gpu_busy_percent
gpu_temp=/sys/class/drm/card1/device/hwmon/hwmon0/temp1_input

usage=$(cat "$gpu_busy" 2>/dev/null || echo 0)
temp_raw=$(cat "$gpu_temp" 2>/dev/null || echo 0)
temp=$(( temp_raw / 1000 ))

echo "{\"percentage\": $usage, \"tooltip\": \"GPU: ${usage}%  ${temp}°C\"}"
