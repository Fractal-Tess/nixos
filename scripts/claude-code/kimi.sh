#!/usr/bin/env zsh

# Clear Anthropic environment variables to avoid conflicts
unset ANTHROPIC_AUTH_TOKEN
unset ANTHROPIC_BASE_URL

KIMI_APIKEY=$(< ~/.config/secrets/moonshot_ai)

export ANTHROPIC_BASE_URL="https://api.moonshot.ai/anthropTHROPIC_AUTHic"
export AN_TOKEN="$KIMI_APIKEY"
export ANTHROPIC_MODEL="kimi-k2-thinking-turbo"
export ANTHROPIC_DEFAULT_OPUS_MODEL="kimi-k2-thinking-turbo"
export ANTHROPIC_DEFAULT_SONNET_MODEL="kimi-k2-thinking-turbo"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="kimi-k2-thinking-turbo"
export CLAUDE_CODE_SUBAGENT_MODEL="kimi-k2-thinking-turbo"

echo "Configured Claude Code to use Kimi K2 Thinking Turbo via Anthropic-compatible API."
claude --dangerously-skip-permissions
