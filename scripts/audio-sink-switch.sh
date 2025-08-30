# Audio sink switching script for waybar
# Cycles between available audio output sinks

# Get current default sink ID
current=$(wpctl status | grep '\*' | grep 'Analog Stereo' | grep -o '\*[[:space:]]*[0-9]\+' | grep -o '[0-9]\+')

# Get all available sink IDs
sinks=($(wpctl status | sed -n '/Sinks:/,/Sources:/p' | grep 'Analog Stereo' | sed 's/.*[[:space:]]\([0-9]\+\)\. .*/\1/'))

# Debug output (uncomment to see what's found)
# echo "Current: $current"
# echo "Sinks: ${sinks[@]}"

# If we have multiple sinks, cycle to next one
if [ ${#sinks[@]} -gt 1 ]; then
    for i in "${!sinks[@]}"; do
        if [[ "${sinks[$i]}" == "$current" ]]; then
            next=$(( (i+1) % ${#sinks[@]} ))
            wpctl set-default ${sinks[$next]}
            break
        fi
    done
fi