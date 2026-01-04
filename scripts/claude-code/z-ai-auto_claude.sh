#!/usr/bin/env zsh

Z_AI_APIKEY=$(< ~/.config/secrets/z-ai/apikey)

export ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic"

export ANTHROPIC_AUTH_TOKEN="$Z_AI_APIKEY"

export ANTHROPIC_DEFAULT_HAIKU_MODEL="glm-4.5-air"
export ANTHROPIC_DEFAULT_SONNET_MODEL="glm-4.7"
export ANTHROPIC_DEFAULT_OPUS_MODEL="glm-4.7"
export GRAPHITI_ENABLED=true

appimage-run ./Auto-Claude-2.7.1-linux-x86_64.AppImage
