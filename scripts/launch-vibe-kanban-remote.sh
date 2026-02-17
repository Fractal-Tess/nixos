#!/usr/bin/env bash
#
# Vibe-Kanban Launch Script
# Launches vibe-kanban with configuration for vibe-kanban.fractal-tess.xyz
#

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# ============================================================================
# VIBE-KANBAN ENVIRONMENT VARIABLES
# ============================================================================

# Remote API Base URL
# Set this to connect to a remote vibe-kanban server for remote features
# Leave empty for local-only mode (no remote features)
# Example: https://api.vibekanban.com or https://vibe-kanban.fractal-tess.xyz
export VK_SHARED_API_BASE="${VK_SHARED_API_BASE:-https://vibe-kanban.fractal-tess.xyz}"
export VITE_VK_SHARED_API_BASE="${VITE_VK_SHARED_API_BASE:-${VK_SHARED_API_BASE}}"

# Allowed Origins for CORS
# Required when running behind a reverse proxy or on a custom domain
# Comma-separated list of origins allowed to make backend API requests
# Not needed for local development (defaults to empty)
export VK_ALLOWED_ORIGINS="${VK_ALLOWED_ORIGINS:-}"

# ============================================================================
# PORT CONFIGURATION
# ============================================================================

# Backend server port (high port as requested)
export BACKEND_PORT="${BACKEND_PORT:-31112}"

# Frontend dev server port (only used in dev mode)
export FRONTEND_PORT="${FRONTEND_PORT:-31111}"

# Production port (auto-assigned if not set)
# export PORT="${PORT:-31112}"

# Backend server host
export HOST="${HOST:-0.0.0.0}"

# MCP server connection configuration
export MCP_HOST="${MCP_HOST:-127.0.0.1}"
export MCP_PORT="${MCP_PORT:-${BACKEND_PORT}}"

# ============================================================================
# OPTIONAL CONFIGURATION
# ============================================================================

# Disable git worktree cleanup (for debugging)
# export DISABLE_WORKTREE_CLEANUP="${DISABLE_WORKTREE_CLEANUP:-}"

# Analytics configuration (build-time variables)
# export POSTHOG_API_KEY="${POSTHOG_API_KEY:-}"
# export POSTHOG_API_ENDPOINT="${POSTHOG_API_ENDPOINT:-}"

# Logging level
export RUST_LOG="${RUST_LOG:-info}"

# ============================================================================
# INTERNAL VARIABLES (automatically set by vibe-kanban at runtime)
# ============================================================================
# These are injected by the server into execution processes:
# - VK_WORKSPACE_ID: Workspace ID
# - VK_WORKSPACE_BRANCH: Workspace branch
# - VK_SESSION_ID: Session ID
# - VK_PROJECT_NAME: Project name
# You should NOT set these manually.

# ============================================================================
# DEPENDENCY CHECKS
# ============================================================================

check_command() {
    local cmd=$1
    local install_msg=$2

    if ! command -v "$cmd" &> /dev/null; then
        log_error "$cmd not found!"
        log_error "$install_msg"
        return 1
    fi
    return 0
}

log_step "Checking dependencies..."

# Check for required commands
DEPS_OK=true

if ! check_command git "Please install git"; then
    DEPS_OK=false
fi

if ! check_command pnpm "Please install pnpm: npm install -g pnpm"; then
    DEPS_OK=false
fi

if ! check_command cargo "Please install Rust: https://rustup.rs"; then
    log_warn "cargo not found in PATH, but may be available in dev environment"
fi

if [ "$DEPS_OK" = false ]; then
    log_error "Missing required dependencies. Please install them and try again."
    exit 1
fi

log_info "All dependencies found!"

# ============================================================================
# REPOSITORY SETUP
# ============================================================================

VIBE_KANBAN_REPO="${VIBE_KANBAN_REPO:-$HOME/dev/vibe-kanban}"
REPO_URL="https://github.com/Fractal-Tess/vibe-kanban.git"

# Create /tmp directory if it doesn't exist
mkdir -p /tmp

if [ ! -d "$VIBE_KANBAN_REPO" ]; then
    log_step "Cloning vibe-kanban repository to $VIBE_KANBAN_REPO..."

    if ! git clone "$REPO_URL" "$VIBE_KANBAN_REPO"; then
        log_error "Failed to clone repository"
        exit 1
    fi

    log_info "Repository cloned successfully!"
else
    log_step "Updating vibe-kanban repository..."

    cd "$VIBE_KANBAN_REPO"

    # Check if repo is clean
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        log_warn "Repository has uncommitted changes, skipping update"
    else
        if ! git pull --ff-only 2>/dev/null; then
            log_warn "Failed to update repository, using existing version"
        else
            log_info "Repository updated successfully!"
        fi
    fi
fi

# ============================================================================
# INSTALL DEPENDENCIES
# ============================================================================

cd "$VIBE_KANBAN_REPO"

log_step "Installing/updating dependencies..."

# Always run pnpm install to ensure dependencies are fresh
# pnpm is smart enough to skip if nothing changed
if ! pnpm install --prefer-offline 2>&1 | grep -v "Progress:"; then
    log_error "Failed to install dependencies"
    exit 1
fi

log_info "Dependencies ready!"

# ============================================================================
# INSTALL NPX-CLI DEPENDENCIES (if production build exists)
# ============================================================================

if [ -f "npx-cli/bin/cli.js" ] && [ -d "npx-cli/dist" ]; then
    log_step "Installing npx-cli dependencies..."

    cd npx-cli
    if ! pnpm install --ignore-workspace --prefer-offline 2>&1 | grep -v "Progress:"; then
        log_error "Failed to install npx-cli dependencies"
        exit 1
    fi
    cd ..

    log_info "npx-cli dependencies ready!"
fi

# ============================================================================
# LAUNCH
# ============================================================================

log_info "Starting vibe-kanban..."
log_info "Repository: $VIBE_KANBAN_REPO"
log_info "Backend Port: ${BACKEND_PORT}"
log_info "Frontend Port: ${FRONTEND_PORT}"
log_info "Host: ${HOST}"
log_info "Remote API Base: ${VK_SHARED_API_BASE:-<disabled - local-only mode>}"
log_info "Allowed Origins: ${VK_ALLOWED_ORIGINS:-<not set>}"
log_info "MCP Host: ${MCP_HOST}"
log_info "MCP Port: ${MCP_PORT}"

echo ""
log_step "Launching vibe-kanban..."

# Load direnv environment if .envrc exists
if [ -f ".envrc" ]; then
    log_info "Loading direnv environment..."
    eval "$(direnv export bash 2>/dev/null)" || log_warn "Failed to load direnv, continuing anyway..."
fi

# Check if built version exists
if [ -f "npx-cli/bin/cli.js" ] && [ -d "npx-cli/dist" ]; then
    log_info "Running production build..."
    cd npx-cli
    exec node bin/cli.js
else
    log_warn "Production build not found, running in development mode..."
    cd "$VIBE_KANBAN_REPO"
    exec pnpm run dev
fi
