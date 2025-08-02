# Script to output NVIDIA GPU status in JSON for Waybar
nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total --format=csv,noheader,nounits | \
awk -F', ' '{printf "{\"percentage\": %d, \"text\": \"%d%%\", \"tooltip\": \"GPU Usage: %d%%\\rTemperature: %d°C\\rMemory: %d/%d MB\", \"class\": \"%s\"}\n", $1, $1, $1, $2, $3, $4, ($1<30 ? "low" : ($1<70 ? "medium" : "high"))}' 
