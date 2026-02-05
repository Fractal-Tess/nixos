# Create the screenshots directory if it doesn't exist
mkdir -p ~/Pictures/screenshots

# Generate the filename with timestamp
filename=~/Pictures/screenshots/screenshot_$(date +%Y%m%d_%H%M%S).png

# Take the screenshot using satty (region selection + annotation tool)
# Satty provides a GUI for selecting the region and optional annotation
satty --output-filename "$filename"

# Check if screenshot was taken (satty returns after user saves or cancels)
if [ -f "$filename" ]; then
    # Copy the saved image to clipboard
    wl-copy < "$filename"

    # Notify the user
    notify-send "Screenshot saved" "File: $filename"
else
    notify-send "Screenshot cancelled" "No screenshot was saved"
fi
