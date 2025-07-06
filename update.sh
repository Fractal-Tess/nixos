#!/usr/bin/env bash

# NixOS Update Script
# This script performs a complete NixOS update workflow with error handling

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# Function to get the last commit message and increment it
get_next_commit_message() {
    local last_message
    last_message=$(git log -1 --pretty=format:"%s" 2>/dev/null || echo "Initial commit")
    
    # Check if the last message follows the pattern "Update #N"
    if [[ $last_message =~ ^Update\ #([0-9]+)$ ]]; then
        local current_num=${BASH_REMATCH[1]}
        local next_num=$((current_num + 1))
        echo "Update #$next_num"
    else
        echo "Update #1"
    fi
}

# Function to reset git staging area
reset_git_staging() {
    print_warning "Resetting git staging area..."
    git reset HEAD
    print_success "Git staging area reset successfully"
}

# Function to handle errors
handle_error() {
    local exit_code=$?
    print_error "Script failed with exit code $exit_code"
    
    # Reset git staging area if we had staged files
    if [[ -n "$(git diff --cached --name-only 2>/dev/null)" ]]; then
        reset_git_staging
    fi
    
    exit $exit_code
}

# Set up error handling
trap handle_error ERR

# Main script execution
main() {
    print_step "Starting NixOS update workflow..."
    echo

    # Step 0: Pull latest changes from remote
    print_step "Step 0: Pulling latest changes from remote repository"
    print_status "Running git pull to fetch and merge remote changes..."
    local git_pull_output
    git_pull_output=$(git pull 2>&1)
    if [[ $? -eq 0 ]]; then
        print_success "Pulled latest changes from remote successfully"
    else
        print_error "Git pull failed"
        exit 1
    fi
    echo "$git_pull_output"
    echo

    # Check if remote changes were pulled
    local remote_updated=1
    if echo "$git_pull_output" | grep -q -E "Already up[- ]to[- ]date\.|Already up to date"; then
        remote_updated=0
    fi

    if [[ $remote_updated -eq 1 ]]; then
        print_step "Remote changes detected and applied. Proceeding to rebuild NixOS configuration. Skipping local staging, commit, and push steps."
        echo
        # Rebuild NixOS configuration for new remote changes
        print_step "Rebuilding NixOS configuration for remote changes"
        print_status "Running nixos-rebuild switch..."
        echo
        if sudo nixos-rebuild switch --flake . --impure --show-trace; then
            print_success "NixOS rebuild completed successfully"
        else
            print_error "NixOS rebuild failed"
            exit 1
        fi
        echo
        print_success "NixOS configuration has been updated from remote changes."
        print_status "Summary:"
        print_status "  - Pulled and applied latest remote changes."
        print_status "  - Configuration rebuilt and activated."
        print_status "  - No local changes to stage, commit, or push."
        echo
        exit 0
    else
        # Step 1: Show git diff from last commit
        print_step "Step 1: Showing git diff from last commit"
        print_status "Displaying changes since last commit..."
        echo
        if git diff --name-only HEAD 2>/dev/null | grep -q .; then
            git diff HEAD
            echo
        else
            print_warning "No changes detected since last commit"
        fi
    fi
    
    # Step 2: Git add all files
    print_step "Step 2: Staging all files"
    print_status "Adding all files to git staging area..."
    git add -A
    print_success "All files staged successfully"
    echo
    
    # Step 3: NixOS rebuild
    print_step "Step 3: Rebuilding NixOS configuration"
    print_status "Running nixos-rebuild switch..."
    echo
    
    # Run nixos-rebuild with real-time output and color preservation
    if sudo nixos-rebuild switch --flake . --impure --show-trace; then
        print_success "NixOS rebuild completed successfully"
    else
        print_error "NixOS rebuild failed"
        reset_git_staging
        exit 1
    fi
    echo
    
    # Step 4: Git commit with incrementing message
    print_step "Step 4: Committing changes"
    local commit_message
    commit_message=$(get_next_commit_message)
    print_status "Committing with message: $commit_message"
    
    if git commit -m "$commit_message"; then
        print_success "Changes committed successfully"
    else
        print_error "Git commit failed"
        exit 1
    fi
    echo
    
    # Step 5: Git push to remote
    print_step "Step 5: Pushing to remote repository"
    print_status "Pushing changes to remote..."
    
    if git push; then
        print_success "Changes pushed to remote successfully"
    else
        print_error "Git push failed"
        exit 1
    fi
    echo
    
    # Step 6: Success message
    print_step "Update workflow completed successfully!"
    print_success "NixOS configuration has been updated and deployed"
    print_success "All changes have been committed and pushed to remote"
    echo
    print_status "Summary:"
    print_status "  - Configuration rebuilt and activated"
    print_status "  - Changes committed: $commit_message"
    print_status "  - Changes pushed to remote repository"
    echo
}

# Change to the NixOS configuration directory
print_step "Changing to NixOS configuration directory..."
if [[ ! -d ~/nixos ]]; then
    print_error "NixOS configuration directory ~/nixos does not exist"
    exit 1
fi

cd ~/nixos
print_success "Changed to $(pwd)"
echo

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_error "Not in a git repository. Please ensure ~/nixos is a git repository."
    exit 1
fi

# Check if we have sudo privileges
if ! sudo -n true 2>/dev/null; then
    print_warning "This script requires sudo privileges for nixos-rebuild"
    print_status "You may be prompted for your password"
fi

# Run the main function
main "$@"
