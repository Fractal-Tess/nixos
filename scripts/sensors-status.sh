#!/usr/bin/env bash
# Script to output GPU and CPU temperature in JSON for Waybar

# Get GPU temperature (NVIDIA)
gpu_temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits | head -n1)

# Get CPU temperature (first core, fallback to average if needed)
# This assumes 'sensors' is installed and outputs a line like: 'Package id 0:  +49.0°C  (high = +80.0°C, crit = +100.0°C)'
cpu_temp=$(sensors | awk '/^Package id 0:/ {gsub("[+.°C]", "", $4); print int($4)}' | head -n1)

# Fallback if above doesn't work (try 'Tctl' for AMD CPUs)
if [ -z "$cpu_temp" ]; then
  cpu_temp=$(sensors | awk '/^Tctl:/ {gsub("[+.°C]", "", $2); print int($2)}' | head -n1)
fi

# Set text and tooltip
text=" ${cpu_temp:-?}°C  ${gpu_temp:-?}°C"
tooltip="CPU Temp: ${cpu_temp:-N/A}°C\nGPU Temp: ${gpu_temp:-N/A}°C"

# Output JSON for Waybar
printf '{"text": "%s", "tooltip": "%s"}\n' "$text" "$tooltip" 