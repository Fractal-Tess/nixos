# lib/utils.fish — Shared logging helpers for fish scripts
#
# Provides colored log_* functions for consistent terminal output.
# Must be sourced before use — do NOT execute directly.
#
# Usage: source ~/nixos/scripts/lib/utils.fish

function log_header
    printf "\033[1;34m==> %s\033[0m\n" "$argv"
end

function log_info
    printf "\033[0;36m :: %s\033[0m\n" "$argv"
end

function log_success
    printf "\033[0;32m  ✓ %s\033[0m\n" "$argv"
end

function log_warn
    printf "\033[0;33m  ! %s\033[0m\n" "$argv"
end

function log_error
    printf "\033[0;31m  ✗ %s\033[0m\n" "$argv" >&2
end

function log_step
    printf "\033[0;35m -> %s\033[0m\n" "$argv"
end
