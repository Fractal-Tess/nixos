#!/usr/bin/env bash

#==============================================================================
# NixOS Flake Update Script
# A comprehensive update workflow for NixOS configurations with git integration
#==============================================================================

set -euo pipefail

# Configuration
readonly NIXOS_DIR="/home/fractal-tess/nixos"
readonly FLAKE_PATH="${NIXOS_DIR}"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly DIM='\033[2m'
readonly NC='\033[0m'

# Symbols
readonly CHECKMARK="✓"
readonly CROSSMARK="✗"
readonly ARROW="→"
readonly BULLET="•"

#==============================================================================
# Output Functions
#==============================================================================

print_header() {
    echo -e "\n${PURPLE}${BOLD}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}${BOLD}  $1${NC}"
    echo -e "${PURPLE}${BOLD}══════════════════════════════════════════════════════════════${NC}\n"
}

print_info() {
    echo -e "${BLUE}${BULLET}${NC} $1"
}

print_success() {
    echo -e "${GREEN}${CHECKMARK}${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}${CROSSMARK} ERROR:${NC} $1"
}

print_step() {
    echo -e "\n${CYAN}${ARROW}${NC} ${BOLD}$1${NC}"
}

print_dim() {
    echo -e "${DIM}$1${NC}"
}

#==============================================================================
# ASCII Art Banner
#==============================================================================

show_banner() {
    local hostname="${HOSTNAME:-$(hostname)}"
    local current_gen
    current_gen=$(nixos-rebuild list-generations 2>/dev/null | grep 'current' | head -1 | awk '{print $1}' || echo "?")
    local kernel
    kernel=$(uname -r)
    local last_commit
    last_commit=$(git log -1 --pretty=format:"%h - %s (%cr)" 2>/dev/null || echo "No commits")
    local branch
    branch=$(git branch --show-current 2>/dev/null || echo "unknown")
    local total_commits
    total_commits=$(git rev-list --count HEAD 2>/dev/null || echo "0")
    local local_changes
    local_changes=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    
    echo -e "${CYAN}"
    cat << 'EOF'
                  ◢██◣   ◥███◣  ◢██◣
                  ◥███◣   ◥███◣◢███◤
                   ◥███◣   ◥██████◤
               ◢████████████◣████◤   ◢◣
              ◢██████████████◣███◣  ◢██◣
                   ◢███◤      ◥███◣◢███◤
                  ◢███◤        ◥██◤███◤
           ◢█████████◤          ◥◤████████◣
           ◥████████◤◣          ◢█████████◤
               ◢███◤██◣        ◢███◤
              ◢███◤◥███◣      ◢███◤
              ◥██◤  ◥███◣██████████████◤
               ◥◤   ◢████◣████████████◤
                   ◢██████◣   ◥███◣
                  ◢███◤◥███◣   ◥███◣
                  ◥██◤  ◥███◣   ◥██◤
EOF
    echo -e "${NC}"
    echo -e "${BOLD}${CYAN}             NixOS Flake Update Manager${NC}"
    echo
    
    echo -e "${BOLD}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BOLD}│${NC}  ${CYAN}System Information${NC}                                         ${BOLD}│${NC}"
    echo -e "${BOLD}├─────────────────────────────────────────────────────────────┤${NC}"
    printf "${BOLD}│${NC}  %-18s ${GREEN}%-40s${NC}${BOLD}│${NC}\n" "Hostname:" "$hostname"
    printf "${BOLD}│${NC}  %-18s ${GREEN}%-40s${NC}${BOLD}│${NC}\n" "Generation:" "$current_gen"
    printf "${BOLD}│${NC}  %-18s ${GREEN}%-40s${NC}${BOLD}│${NC}\n" "Kernel:" "$kernel"
    echo -e "${BOLD}├─────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${BOLD}│${NC}  ${CYAN}Repository Status${NC}                                          ${BOLD}│${NC}"
    echo -e "${BOLD}├─────────────────────────────────────────────────────────────┤${NC}"
    printf "${BOLD}│${NC}  %-18s ${YELLOW}%-40s${NC}${BOLD}│${NC}\n" "Branch:" "$branch"
    printf "${BOLD}│${NC}  %-18s ${YELLOW}%-40s${NC}${BOLD}│${NC}\n" "Total Commits:" "$total_commits"
    printf "${BOLD}│${NC}  %-18s ${YELLOW}%-40s${NC}${BOLD}│${NC}\n" "Local Changes:" "$local_changes file(s)"
    echo -e "${BOLD}├─────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${BOLD}│${NC}  ${CYAN}Last Commit${NC}                                                ${BOLD}│${NC}"
    echo -e "${BOLD}│${NC}  ${DIM}$(echo "$last_commit" | cut -c1-59)${NC}  ${BOLD}│${NC}"
    echo -e "${BOLD}└─────────────────────────────────────────────────────────────┘${NC}"
    echo
}

#==============================================================================
# Git Functions
#==============================================================================

check_git_conflicts() {
    print_step "Checking for remote changes..."
    
    # Fetch latest from remote
    if ! git fetch origin 2>/dev/null; then
        print_error "Failed to fetch from remote. Check your network connection."
        exit 1
    fi
    
    local branch
    branch=$(git branch --show-current)
    
    # Check if there are remote changes
    local behind
    behind=$(git rev-list --count HEAD..origin/"$branch" 2>/dev/null || echo "0")
    local ahead
    ahead=$(git rev-list --count origin/"$branch"..HEAD 2>/dev/null || echo "0")
    
    if [[ "$behind" -eq 0 ]]; then
        print_success "Already up to date with remote"
        return 0
    fi
    
    print_info "Remote has $behind new commit(s)"
    
    # Check if we have local uncommitted changes that might conflict
    if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
        print_warning "You have local uncommitted changes"
        
        # Try to stash, pull, then unstash
        print_info "Stashing local changes..."
        if ! git stash push -m "update-script-autostash-$(date +%s)" 2>/dev/null; then
            print_error "Failed to stash local changes"
            print_error "Please commit or stash your changes manually before running this script"
            exit 1
        fi
        
        # Try to pull
        if git pull --rebase origin "$branch" 2>/dev/null; then
            print_success "Pulled remote changes successfully"
            
            # Try to restore stashed changes
            if git stash pop 2>/dev/null; then
                print_success "Restored local changes"
            else
                print_error "Conflict detected when restoring local changes!"
                print_error "Your changes are saved in git stash. Resolve conflicts manually:"
                echo
                print_dim "  1. Run: git stash show -p"
                print_dim "  2. Resolve conflicts manually"
                print_dim "  3. Run: git stash drop"
                echo
                exit 1
            fi
        else
            # Pull failed, restore stash and exit
            git stash pop 2>/dev/null || true
            print_error "Failed to pull remote changes. Conflicts detected!"
            print_error "Please resolve conflicts manually:"
            echo
            print_dim "  1. Run: git fetch origin"
            print_dim "  2. Run: git merge origin/$branch (or git rebase origin/$branch)"
            print_dim "  3. Resolve any conflicts"
            print_dim "  4. Run this script again"
            echo
            exit 1
        fi
    else
        # No local changes, just pull
        if git pull --rebase origin "$branch" 2>/dev/null; then
            print_success "Pulled $behind commit(s) from remote"
        else
            print_error "Failed to pull remote changes!"
            print_error "Please resolve manually and run this script again"
            exit 1
        fi
    fi
    
    return 0
}

stage_local_changes() {
    print_step "Staging local changes..."
    
    local changes
    changes=$(git status --porcelain 2>/dev/null)
    
    if [[ -z "$changes" ]]; then
        print_info "No local changes to stage"
        return 1
    fi
    
    # Show what will be staged
    print_info "Files to be staged:"
    echo "$changes" | while read -r line; do
        local status="${line:0:2}"
        local file="${line:3}"
        case "$status" in
            "??") echo -e "  ${GREEN}+ (new)${NC}     $file" ;;
            " M"|"M "|"MM") echo -e "  ${YELLOW}~ (modified)${NC} $file" ;;
            " D"|"D ") echo -e "  ${RED}- (deleted)${NC}  $file" ;;
            *) echo -e "  ${BLUE}? ($status)${NC}   $file" ;;
        esac
    done
    echo
    
    # Stage all changes
    git add -A
    print_success "All changes staged"
    return 0
}

get_next_commit_number() {
    local last_msg
    last_msg=$(git log -1 --pretty=format:"%s" 2>/dev/null || echo "")
    
    if [[ $last_msg =~ ^Update\ #([0-9]+) ]]; then
        echo $((${BASH_REMATCH[1]} + 1))
    else
        # Count all "Update #N" commits and add 1
        local max_num
        max_num=$(git log --pretty=format:"%s" 2>/dev/null | grep -oP 'Update #\K[0-9]+' | sort -rn | head -1 || echo "0")
        echo $((max_num + 1))
    fi
}

commit_changes() {
    print_step "Committing changes..."
    
    if [[ -z "$(git diff --cached --name-only 2>/dev/null)" ]]; then
        print_info "No staged changes to commit"
        return 1
    fi
    
    local commit_num
    commit_num=$(get_next_commit_number)
    local commit_msg="Update #${commit_num}"
    
    if git commit -m "$commit_msg" >/dev/null 2>&1; then
        print_success "Committed: $commit_msg"
        return 0
    else
        print_error "Failed to commit changes"
        return 1
    fi
}

push_changes() {
    print_step "Pushing to remote..."
    
    local branch
    branch=$(git branch --show-current)
    
    if git push origin "$branch" 2>/dev/null; then
        print_success "Pushed to origin/$branch"
        return 0
    else
        print_error "Failed to push changes"
        print_warning "You may need to push manually: git push origin $branch"
        return 1
    fi
}

#==============================================================================
# NixOS Functions
#==============================================================================

rebuild_nixos() {
    print_step "Rebuilding NixOS configuration..."
    
    local hostname
    hostname=$(hostname)
    
    print_info "Host: $hostname"
    print_info "Flake: ${FLAKE_PATH}#${hostname}"
    echo
    
    # Run rebuild with full output
    echo -e "${DIM}─────────────────────────────────────────────────────────────${NC}"
    
    if sudo nixos-rebuild switch --flake "${FLAKE_PATH}#${hostname}" --impure 2>&1; then
        echo -e "${DIM}─────────────────────────────────────────────────────────────${NC}"
        echo
        print_success "NixOS rebuild completed successfully"
        
        # Show new generation info
        local new_gen
        new_gen=$(nixos-rebuild list-generations 2>/dev/null | grep 'current' | head -1 || echo "unknown")
        print_info "Current generation: $new_gen"
        
        return 0
    else
        echo -e "${DIM}─────────────────────────────────────────────────────────────${NC}"
        echo
        print_error "NixOS rebuild failed!"
        print_error "Please check the error output above and fix the issues."
        echo
        
        # Reset staged changes on failure
        if [[ -n "$(git diff --cached --name-only 2>/dev/null)" ]]; then
            print_warning "Unstaging changes due to build failure..."
            git reset HEAD >/dev/null 2>&1
        fi
        
        exit 1
    fi
}

#==============================================================================
# Summary Functions
#==============================================================================

show_summary() {
    local had_changes=$1
    local pushed=$2
    
    print_header "Update Complete"
    
    local new_gen
    new_gen=$(nixos-rebuild list-generations 2>/dev/null | grep 'current' | head -1 | awk '{print $1}' || echo "?")
    local last_commit
    last_commit=$(git log -1 --pretty=format:"%h - %s" 2>/dev/null || echo "None")
    
    echo -e "${GREEN}"
    cat << 'EOF'
    ╔═══════════════════════════════════════════╗
    ║                                           ║
    ║   ✓ System successfully updated!          ║
    ║                                           ║
    ╚═══════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    echo -e "  ${BOLD}Summary:${NC}"
    echo -e "  ${BULLET} Generation: ${GREEN}$new_gen${NC}"
    echo -e "  ${BULLET} Last commit: ${CYAN}$last_commit${NC}"
    
    if [[ "$had_changes" == "true" ]]; then
        if [[ "$pushed" == "true" ]]; then
            echo -e "  ${BULLET} Changes: ${GREEN}Committed and pushed${NC}"
        else
            echo -e "  ${BULLET} Changes: ${YELLOW}Committed (push pending)${NC}"
        fi
    else
        echo -e "  ${BULLET} Changes: ${DIM}No local changes${NC}"
    fi
    
    echo
    
    # Show recent generations
    echo -e "  ${BOLD}Recent Generations:${NC}"
    nixos-rebuild list-generations 2>/dev/null | tail -5 | while read -r line; do
        if echo "$line" | grep -q "current"; then
            echo -e "  ${GREEN}${ARROW} $line${NC}"
        else
            echo -e "  ${DIM}  $line${NC}"
        fi
    done
    echo
}

#==============================================================================
# Main
#==============================================================================

main() {
    # Change to nixos directory
    if [[ ! -d "$NIXOS_DIR" ]]; then
        print_error "NixOS configuration directory not found: $NIXOS_DIR"
        exit 1
    fi
    cd "$NIXOS_DIR"
    
    # Verify git repository
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        print_error "Not a git repository: $NIXOS_DIR"
        exit 1
    fi
    
    # Show banner
    show_banner
    
    # Check sudo access
    if ! sudo -v; then
        print_error "This script requires sudo privileges"
        exit 1
    fi
    
    # Step 1: Pull latest changes (handles conflicts)
    check_git_conflicts
    
    # Step 2: Stage local changes (required for nix flake)
    local had_changes="false"
    if stage_local_changes; then
        had_changes="true"
    fi
    
    # Step 3: Rebuild NixOS
    rebuild_nixos
    
    # Step 4: Commit and push if we had changes
    local pushed="false"
    if [[ "$had_changes" == "true" ]]; then
        if commit_changes; then
            if push_changes; then
                pushed="true"
            fi
        fi
    fi
    
    # Show summary
    show_summary "$had_changes" "$pushed"
}

# Run main
main "$@"
