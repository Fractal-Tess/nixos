#!/usr/bin/env zsh

# Clear Anthropic environment variables to avoid conflicts (per MiniMax docs)
unset ANTHROPIC_AUTH_TOKEN
unset ANTHROPIC_BASE_URL

MINIMAX_APIKEY=$(< ~/.config/secrets/minimax/apikey)

export ANTHROPIC_BASE_URL="https://api.minimax.io/anthropic"
export ANTHROPIC_AUTH_TOKEN="$MINIMAX_APIKEY"
export ANTHROPIC_MODEL="MiniMax-M2.1"
export ANTHROPIC_SMALL_FAST_MODEL="MiniMax-M2.1"
export ANTHROPIC_DEFAULT_SONNET_MODEL="MiniMax-M2.1"
export ANTHROPIC_DEFAULT_OPUS_MODEL="MiniMax-M2.1"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="MiniMax-M2.1"
export GRAPHITI_ENABLED=true

appimage-run ~/.local/bin/Auto-Claude-2.7.1-linux-x86_64.AppImage
