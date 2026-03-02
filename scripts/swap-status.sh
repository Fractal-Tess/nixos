# Script to output swap usage status in JSON for Waybar
# Returns percentage used, tooltip info, and CSS class

awk '
/^SwapTotal:/ {
    total = $2
}
/^SwapFree:/ {
    free = $2
}
END {
    if (total > 0) {
        used = total - free
        pct = int((used / total) * 100)
        used_mb = int(used / 1024)
        total_mb = int(total / 1024)
        
        # Determine CSS class based on usage
        if (pct < 30) class = "low"
        else if (pct < 70) class = "medium"
        else class = "high"
        
        printf "{\"percentage\": %d, \"text\": \"%d%%\", \"tooltip\": \"Swap: %d/%d MB (%d%%)\", \"class\": \"%s\"}\n", pct, pct, used_mb, total_mb, pct, class
    } else {
        # No swap available
        printf "{\"percentage\": 0, \"text\": \"N/A\", \"tooltip\": \"No swap available\", \"class\": \"low\"}\n"
    }
}
' /proc/meminfo
