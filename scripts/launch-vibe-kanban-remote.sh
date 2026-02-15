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

# ============================================================================
# VIBE-KANBAN ENVIRONMENT VARIABLES
# ============================================================================

# Remote API Base URL
# Set this to connect to a remote vibe-kanban server for remote features
# Example: https://api.vibekanban.com or http://localhost:3000
export VK_SHARED_API_BASE="${VK_SHARED_API_BASE:-https://vibe-kanban.fractal-tess.xyz}"
export VITE_VK_SHARED_API_BASE="${VITE_VK_SHARED_API_BASE:-${VK_SHARED_API_BASE}}"

# Allowed Origins for CORS
# Required when running behind a reverse proxy or on a custom domain
# Comma-separated list of origins allowed to make backend API requests
export VK_ALLOWED_ORIGINS="${VK_ALLOWED_ORIGINS:-https://vibe-kanban.fractal-tess.xyz,http://localhost:31111}"

# ============================================================================
# PORT CONFIGURATION
# ============================================================================

# Backend server port (high port as requested)
export BACKEND_PORT="${BACKEND_PORT:-31112}"

# Frontend dev server port (only used in dev mode)
export FRONTEND_PORT="${FRONTEND_PORT:-31111}"

# Production port (auto-assigned if not set)
# export PORT="${PORT:-9090}"

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
# LAUNCH
# ============================================================================

log_info "Starting vibe-kanban..."
log_info "Backend Port: ${BACKEND_PORT}"
log_info "Host: ${HOST}"
log_info "Remote API Base: ${VK_SHARED_API_BASE}"
log_info "Allowed Origins: ${VK_ALLOWED_ORIGINS}"
log_info "MCP Host: ${MCP_HOST}"
log_info "MCP Port: ${MCP_PORT}"

echo ""

# Find the vibe-kanban binary
# First check if we're in a dev environment with pnpm
if command -v pnpm &> /dev/null && [ -f "package.json" ]; then
    log_info "Detected pnpm project. Running in development mode..."
    exec pnpm run dev
# Check for npx global installation
elif command -v vibe-kanban &> /dev/null; then
    log_info "Found vibe-kanban in PATH. Launching..."
    exec vibe-kanban
# Check for local binary
elif [ -f "./vibe-kanban" ]; then
    log_info "Found local vibe-kanban binary. Launching..."
    exec ./vibe-kanban
else
    log_error "vibe-kanban not found!"
    log_error "Please either:"
    log_error "  1. Run this script from a vibe-kanban project directory (with package.json)"
    log_error "  2. Install vibe-kanban globally: npm install -g vibe-kanban"
    log_error "  3. Set VIBE_KANBAN_BIN environment variable to the binary path"
    log_error "  4. Place the vibe-kanban binary in the current directory"
    exit 1
fi
