#!/bin/bash

# Git Worktree Shortcuts
# Convenient aliases and shortcuts for the git-worktree-manager
#
# Installation:
#   source scripts/worktree-shortcuts.sh
#   # Or add to ~/.bashrc: source /path/to/worktree-shortcuts.sh
#
# Main aliases: wt, wtcreate, wtlist, wtremove, wtswitch, wtcleanup
# Advanced functions: wtgo, wtcd, wtfork, wtsync
# Type 'wthelp' for full documentation

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Locate the git-worktree-manager script using multiple search strategies
find_worktree_manager() {
    # First, try in the same directory as this script (both naming conventions)
    if [[ -x "$SCRIPT_DIR/git-worktree-manager.sh" ]]; then
        echo "$SCRIPT_DIR/git-worktree-manager.sh"
        return 0
    elif [[ -x "$SCRIPT_DIR/git-worktree-manager" ]]; then
        echo "$SCRIPT_DIR/git-worktree-manager"
        return 0
    fi
    
    # Check if it's in PATH (both naming conventions)
    if command -v git-worktree-manager >/dev/null 2>&1; then
        echo "git-worktree-manager"
        return 0
    elif command -v git-worktree-manager.sh >/dev/null 2>&1; then
        echo "git-worktree-manager.sh"
        return 0
    fi
    
    # Check if it's in a scripts directory relative to current location
    local current_dir="$(pwd)"
    while [[ "$current_dir" != "/" ]]; do
        if [[ -x "$current_dir/scripts/git-worktree-manager.sh" ]]; then
            echo "$current_dir/scripts/git-worktree-manager.sh"
            return 0
        elif [[ -x "$current_dir/scripts/git-worktree-manager" ]]; then
            echo "$current_dir/scripts/git-worktree-manager"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
    done
    
    return 1
}

# Find the worktree manager script
if [[ -n "$WORKTREE_MANAGER" ]] && [[ -x "$WORKTREE_MANAGER" ]]; then
    # Use externally provided WORKTREE_MANAGER variable (for testing)
    true
elif WORKTREE_MANAGER=$(find_worktree_manager); then
    true  # Found it
else
    echo "Error: git-worktree-manager script not found"
    echo "Please ensure the script is:"
    echo "  1. In the same directory as this shortcuts script (as 'git-worktree-manager' or 'git-worktree-manager.sh')"
    echo "  2. In your PATH (try: which git-worktree-manager)"
    echo "  3. In a scripts/ directory in your project"
    echo "  4. Or set WORKTREE_MANAGER environment variable to the script path"
    return 1 2>/dev/null || exit 1
fi

# Main aliases
alias wt="$WORKTREE_MANAGER"
alias worktree="$WORKTREE_MANAGER"

# Command-specific shortcuts
alias wtcreate="$WORKTREE_MANAGER create"
alias wtlist="$WORKTREE_MANAGER list"
alias wtls="$WORKTREE_MANAGER list"
alias wtremove="$WORKTREE_MANAGER remove"
alias wtrm="$WORKTREE_MANAGER remove"
alias wtcleanup="$WORKTREE_MANAGER cleanup"
alias wtswitch="$WORKTREE_MANAGER switch"
alias wtsw="$WORKTREE_MANAGER switch"
alias wtstatus="$WORKTREE_MANAGER status"
alias wtst="$WORKTREE_MANAGER status"
alias wtprune="$WORKTREE_MANAGER prune"

# Advanced functions

# Change directory to worktree for specified branch
wtcd() {
    local branch="$1"
    if [[ -z "$branch" ]]; then
        echo "Usage: wtcd <branch-name>"
        return 1
    fi
    
    # Find worktree path for branch
    local worktree_path=$(git worktree list --porcelain | awk -v branch="$branch" '
        /^worktree/ { path = substr($0, 10) }
        /^branch/ && substr($0, 8) == "refs/heads/" branch { print path; exit }
    ')
    
    if [[ -z "$worktree_path" ]]; then
        echo "No worktree found for branch '$branch'"
        echo "Available worktrees:"
        "$WORKTREE_MANAGER" list
        return 1
    fi
    
    cd "$worktree_path"
}

# Create worktree if needed, then switch to it (most convenient function)
wtgo() {
    local branch="$1"
    if [[ -z "$branch" ]]; then
        echo "Usage: wtgo <branch-name>"
        echo "Creates worktree for branch if it doesn't exist, then switches to it"
        return 1
    fi
    
    # Check if worktree already exists
    local worktree_path=$(git worktree list --porcelain | awk -v branch="$branch" '
        /^worktree/ { path = substr($0, 10) }
        /^branch/ && substr($0, 8) == "refs/heads/" branch { print path; exit }
    ')
    
    if [[ -n "$worktree_path" ]]; then
        echo "Switching to existing worktree for branch '$branch'"
        cd "$worktree_path"
    else
        echo "Creating new worktree for branch '$branch'"
        "$WORKTREE_MANAGER" create "$branch"
        # Get the new worktree path
        worktree_path=$(git worktree list --porcelain | awk -v branch="$branch" '
            /^worktree/ { path = substr($0, 10) }
            /^branch/ && substr($0, 8) == "refs/heads/" branch { print path; exit }
        ')
        if [[ -n "$worktree_path" ]]; then
            cd "$worktree_path"
        fi
    fi
}

# Create a fork/variant of current branch (e.g., feature-auth -> feature-auth-v2)
wtfork() {
    local current_branch=$(git branch --show-current)
    local fork_suffix="${1:-fork}"
    local new_branch="${current_branch}-${fork_suffix}"
    
    echo "Creating fork of '$current_branch' as '$new_branch'"
    "$WORKTREE_MANAGER" create "$new_branch"
}

# Sync all worktrees by running 'git pull' in each one
wtsync() {
    echo "Syncing all worktrees..."
    git worktree list --porcelain | awk '
    /^worktree/ { 
        path = substr($0, 10)
        if (path != "") {
            print "=== Syncing " path " ==="
            system("cd \"" path "\" 2>/dev/null && git pull --ff-only || echo \"Error syncing " path "\"")
        }
    }'
}

# Function to show git status for all worktrees
wtstatusall() {
    "$WORKTREE_MANAGER" status
}

# Tab completion for wtcd and wtgo
if [[ -n "$BASH_VERSION" ]]; then
    _worktree_branches() {
        local cur="${COMP_WORDS[COMP_CWORD]}"
        local branches=$(git worktree list --porcelain | grep '^branch' | sed 's/^branch refs\/heads\///' | sort -u)
        COMPREPLY=($(compgen -W "$branches" -- "$cur"))
    }
    
    complete -F _worktree_branches wtcd wtgo wtswitch wtsw
elif [[ -n "$ZSH_VERSION" ]]; then
    _wtcd() {
        local branches=($(git worktree list --porcelain | grep '^branch' | sed 's/^branch refs\/heads\///' | sort -u))
        _describe 'branches' branches
    }
    
    compdef _wtcd wtcd wtgo wtswitch wtsw
fi

# Help function
wthelp() {
    cat << 'EOF'
Git Worktree Shortcuts

Basic Commands:
  wt, worktree           - Main worktree manager
  wtcreate <branch>      - Create worktree for branch
  wtlist, wtls           - List all worktrees
  wtremove, wtrm <path>  - Remove worktree
  wtcleanup              - Clean up orphaned worktrees
  wtswitch, wtsw <branch>- Switch to worktree
  wtstatus, wtst         - Show status of all worktrees
  wtprune                - Prune worktree references

Advanced Functions:
  wtcd <branch>          - Change directory to worktree for branch
  wtgo <branch>          - Create worktree if needed, then switch to it
  wtfork [suffix]        - Create fork of current branch
  wtsync                 - Pull latest changes in all worktrees
  wtstatusall            - Show git status for all worktrees
  wthelp                 - Show this help

Examples:
  wtgo feature/auth      # Create and switch to auth feature worktree
  wtcd main              # Switch to main branch worktree
  wtfork hotfix          # Create current-branch-hotfix worktree
  wtsync                 # Pull all worktrees

Note: Tab completion is available for branch names in wtcd, wtgo, and wtswitch
EOF
}

echo "Git Worktree shortcuts loaded. Type 'wthelp' for usage information."