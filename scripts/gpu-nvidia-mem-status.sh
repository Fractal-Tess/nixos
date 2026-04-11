#!/usr/bin/env bash
# Script to output NVIDIA GPU memory usage in JSON for Waybar
nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits | \
awk -F', ' '{pct=int($1/$2*100); printf "{\"percentage\": %d, \"text\": \"%d%%\", \"tooltip\": \"GPU Memory: %d/%d MB (%d%%)\", \"class\": \"%s\"}\n", pct, pct, $1, $2, pct, (pct<30 ? "low" : (pct<70 ? "medium" : "high"))}'
