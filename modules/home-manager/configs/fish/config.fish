# Fish shell configuration - migrated from zsh

# ============================================================================
# INITIALIZATION
# ============================================================================

# Load custom secrets (conditional)
if test -f ~/.secrets.fish
  source ~/.secrets.fish
end

# Add scripts to PATH
if test -d ~/nixos/scripts
  fish_add_path ~/nixos/scripts
end

# pnpm configuration
if test -d "$PNPM_HOME"
  fish_add_path "$PNPM_HOME"
end

# ============================================================================
# HYPRLAND INTEGRATION
# ============================================================================

# Auto-start Hyprland on TTY1 if no Wayland session
if status is-login
and test -z "$WAYLAND_DISPLAY"
and test "$XDG_VTNR" = "1"
  exec Hyprland
end

# ============================================================================
# AI TOOLS
# ============================================================================

abbr -a zai "~/nixos/scripts/claude-code/z-ai.sh"
abbr -a minimax "~/nixos/scripts/claude-code/minimax.sh"
abbr -a ca "cursor-agent"

# ============================================================================
# CURSOR INTEGRATION
# ============================================================================

if test -n "$CURSOR_TRACE_ID"
  set -g PROMPT_EOL_MARK ""
  if test -f "$HOME/.iterm2_shell_integration.fish"
    source "$HOME/.iterm2_shell_integration.fish"
  end
end

# ============================================================================
# CLIPBOARD UTILITIES
# ============================================================================

function cc
  wl-copy --primary --trim-newline
end

function cv
  wl-paste --primary --no-newline
end
