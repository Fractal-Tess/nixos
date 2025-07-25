#!/usr/bin/env bash

# Script to get the active graphical session ID
# Returns the session ID of the active graphical session (with seat0)

# Find the active graphical session ID
SESSION_ID=$(loginctl list-sessions --no-legend | grep "seat0" | awk '{print $1}')

if [ -n "$SESSION_ID" ]; then
    echo "$SESSION_ID"
else
    echo "No active graphical session found" >&2
    exit 1
fi 