#!/usr/bin/env bash
# Screenshot with region selection and Satty annotation
# Uses ppm format for faster processing (uncompressed vs png)

# Select region, exit cleanly if cancelled
region=$(slurp) || exit 0

# Capture region and pipe directly to Satty for annotation
# All output/copy behavior is configured in ~/.config/satty/config.toml
grim -g "$region" -t ppm - | satty --filename -
