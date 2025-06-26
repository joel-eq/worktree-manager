#!/bin/bash

# Git Worktree Manager
# Utility script for managing git worktrees efficiently
#
# Features:
# - Create/remove/list worktrees from any directory in git repo
# - Automatically copy config files (.env, .mcp.json, etc.) to new worktrees
# - Smart branch handling (local, remote, or new branches)
# - Cleanup orphaned worktrees and references
#
# Usage: ./git-worktree-manager.sh <command> [options]
# Run with 'help' command for full documentation

set -e

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Find git project root by walking up directory tree
find_git_root() {
    local dir="$(pwd)"
    while [[ "$dir" != "/" ]]; do
        if [[ -d "$dir/.git" ]]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    return 1
}

# Determine PROJECT_ROOT with multiple fallback strategies
if PROJECT_ROOT=$(find_git_root); then
    # Found git root from current directory
    true
elif [[ -d "$SCRIPT_DIR/../.git" ]]; then
    # Fallback: assume script is in project subdirectory
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
else
    # Last resort: use current directory if it's a git repo
    if [[ -d "$(pwd)/.git" ]]; then
        PROJECT_ROOT="$(pwd)"
    else
        echo "Error: Cannot find git repository root" >&2
        echo "Please run this script from within a git repository" >&2
        exit 1
    fi
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DEFAULT_BASE_DIR="../"
WORKTREE_PREFIX=""

# Default config files to copy to new worktrees
DEFAULT_CONFIG_FILES=(
    ".env"
    ".env.local" 
    ".env.development"
    ".env.test"
    ".vscode/settings.json"
    ".vscode/launch.json"
    "config/local.json"
    "config/development.json"
    ".taskmaster/config.json"
    ".mcp.json"
)

# Config file to store user preferences
CONFIG_FILE="$PROJECT_ROOT/.worktree-config"

usage() {
    cat << EOF
Git Worktree Manager - Manage git worktrees efficiently

Usage: $SCRIPT_NAME <command> [options]

Commands:
    create <branch> [path]      Create new worktree for branch
    list                        List all worktrees
    remove <path|branch>        Remove worktree
    cleanup                     Remove stale/orphaned worktrees
    switch <branch>             Switch to worktree for branch
    status                      Show status of all worktrees
    prune                       Prune worktree references
    config                      Manage config file copying settings
    help                        Show this help message

Options:
    -d, --base-dir <dir>        Base directory for worktrees (default: ../)
    -p, --prefix <prefix>       Prefix for worktree directories
    -f, --force                 Force operation (use with caution)
    -v, --verbose               Verbose output
    -c, --copy-configs          Copy config files to new worktree (default)
    --no-copy-configs           Skip copying config files
    --config-files <files>      Comma-separated list of config files to copy

Examples:
    # Create worktree for feature branch
    $SCRIPT_NAME create feature/auth-system

    # Create worktree with custom path
    $SCRIPT_NAME create hotfix/bug-123 ../hotfix-workspace

    # Create worktree without copying config files
    $SCRIPT_NAME create feature/test --no-copy-configs

    # Create worktree with specific config files
    $SCRIPT_NAME create feature/db --config-files ".env,.env.local"

    # List all worktrees
    $SCRIPT_NAME list

    # Remove worktree
    $SCRIPT_NAME remove ../bookreader-mcp-auth

    # Clean up orphaned worktrees
    $SCRIPT_NAME cleanup

    # Switch to existing worktree
    $SCRIPT_NAME switch feature/auth-system

    # Manage config file settings
    $SCRIPT_NAME config --list
    $SCRIPT_NAME config --add .env.production
    $SCRIPT_NAME config --remove .vscode/settings.json

EOF
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Validate we're in a git repository
validate_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "Not in a git repository"
        exit 1
    fi
}

# Get the main/master branch name
get_main_branch() {
    local main_branch
    main_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
    if [[ -z "$main_branch" ]]; then
        main_branch="main"
    fi
    echo "$main_branch"
}

# Load list of config files to copy from .worktree-config or defaults
load_config_files() {
    if [[ -f "$CONFIG_FILE" ]]; then
        # Read file line by line, skip empty lines and comments
        while IFS= read -r line || [[ -n "$line" ]]; do
            # Skip empty lines and comments
            [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
            echo "$line"
        done < "$CONFIG_FILE"
    else
        # If no config file, use defaults
        printf '%s\n' "${DEFAULT_CONFIG_FILES[@]}"
    fi
}

# Save config files list to config file
save_config_files() {
    local files=("$@")
    
    cat > "$CONFIG_FILE" << EOF
# Worktree Manager Configuration
# List of files to copy to new worktrees
# One file path per line, relative to project root
# Lines starting with # are comments

EOF
    
    for file in "${files[@]}"; do
        echo "$file" >> "$CONFIG_FILE"
    done
    
    log_success "Configuration saved to $CONFIG_FILE"
}

# Copy config files from project root to new worktree directory
copy_config_files() {
    local worktree_path="$1"
    local config_files=("${@:2}")
    local copied_count=0
    local failed_count=0
    
    if [[ ${#config_files[@]} -eq 0 ]]; then
        return 0
    fi
    
    log_info "Copying config files to worktree..."
    
    for config_file in "${config_files[@]}"; do
        local source_path="$PROJECT_ROOT/$config_file"
        local target_path="$worktree_path/$config_file"
        local target_dir=$(dirname "$target_path")
        
        if [[ -f "$source_path" ]]; then
            # Create target directory if it doesn't exist
            if [[ ! -d "$target_dir" ]]; then
                mkdir -p "$target_dir"
            fi
            
            if cp "$source_path" "$target_path" 2>/dev/null; then
                log_info "  ✓ Copied: $config_file"
                ((copied_count++))
            else
                log_warning "  ✗ Failed to copy: $config_file"
                ((failed_count++))
            fi
        else
            log_info "  - Skipped: $config_file (not found)"
        fi
    done
    
    if [[ $copied_count -gt 0 ]]; then
        log_success "Copied $copied_count config files"
    fi
    
    if [[ $failed_count -gt 0 ]]; then
        log_warning "Failed to copy $failed_count config files"
    fi
}

# Manage configuration
manage_config() {
    local action="$1"
    local value="$2"
    
    case "$action" in
        --list|list)
            log_info "Current config files to copy:"
            local has_files=false
            
            while IFS= read -r file; do
                [[ -z "$file" ]] && continue
                has_files=true
                if [[ -f "$PROJECT_ROOT/$file" ]]; then
                    echo "  ✓ $file"
                else
                    echo "  - $file (not found)"
                fi
            done < <(load_config_files)
            
            if [[ "$has_files" == "false" ]]; then
                echo "  (none configured)"
            fi
            ;;
        --add|add)
            if [[ -z "$value" ]]; then
                log_error "File path required for --add"
                exit 1
            fi
            
            # Check if already exists
            local exists=false
            while IFS= read -r file; do
                [[ -z "$file" ]] && continue
                if [[ "$file" == "$value" ]]; then
                    exists=true
                    break
                fi
            done < <(load_config_files)
            
            if [[ "$exists" == "true" ]]; then
                log_warning "File '$value' already in config list"
            else
                # Read existing config files into array
                local config_files=()
                while IFS= read -r file; do
                    [[ -z "$file" ]] && continue
                    config_files+=("$file")
                done < <(load_config_files)
                
                config_files+=("$value")
                save_config_files "${config_files[@]}"
                log_success "Added '$value' to config files"
            fi
            ;;
        --remove|remove)
            if [[ -z "$value" ]]; then
                log_error "File path required for --remove"
                exit 1
            fi
            
            local new_config_files=()
            local found=false
            
            while IFS= read -r file; do
                [[ -z "$file" ]] && continue
                if [[ "$file" != "$value" ]]; then
                    new_config_files+=("$file")
                else
                    found=true
                fi
            done < <(load_config_files)
            
            if [[ "$found" == "true" ]]; then
                save_config_files "${new_config_files[@]}"
                log_success "Removed '$value' from config files"
            else
                log_warning "File '$value' not found in config list"
            fi
            ;;
        --reset|reset)
            save_config_files "${DEFAULT_CONFIG_FILES[@]}"
            log_success "Reset config files to defaults"
            ;;
        *)
            log_error "Unknown config action: $action"
            echo "Available actions: --list, --add <file>, --remove <file>, --reset"
            exit 1
            ;;
    esac
}

# Generate worktree directory path from branch name (e.g., ../project-feature-auth)
generate_worktree_path() {
    local branch="$1"
    local base_dir="${2:-$DEFAULT_BASE_DIR}"
    local prefix="${3:-$WORKTREE_PREFIX}"
    
    # Clean branch name for directory (replace special chars with hyphens)
    local clean_branch=$(echo "$branch" | sed 's/[^a-zA-Z0-9._-]/-/g')
    
    # Generate path: ../prefix-projectname-branchname
    local worktree_name="${prefix}$(basename "$PROJECT_ROOT")-${clean_branch}"
    echo "${base_dir}${worktree_name}"
}

# Create new worktree
create_worktree() {
    local branch="$1"
    local custom_path="$2"
    local base_dir="$3"
    local prefix="$4"
    local force="$5"
    local copy_configs="$6"
    local custom_config_files="$7"
    
    if [[ -z "$branch" ]]; then
        log_error "Branch name required"
        exit 1
    fi
    
    # Generate or use custom path
    local worktree_path
    if [[ -n "$custom_path" ]]; then
        worktree_path="$custom_path"
    else
        worktree_path=$(generate_worktree_path "$branch" "$base_dir" "$prefix")
    fi
    
    log_info "Creating worktree for branch '$branch' at '$worktree_path'"
    
    # Check if path already exists
    if [[ -d "$worktree_path" ]] && [[ "$force" != "true" ]]; then
        log_error "Directory '$worktree_path' already exists. Use --force to override."
        exit 1
    fi
    
    # Check if branch exists locally
    if git show-ref --verify --quiet "refs/heads/$branch"; then
        log_info "Branch '$branch' exists locally"
        git worktree add "$worktree_path" "$branch"
    elif git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
        log_info "Branch '$branch' exists on remote, creating local tracking branch"
        git worktree add --track -b "$branch" "$worktree_path" "origin/$branch"
    else
        log_info "Creating new branch '$branch'"
        local main_branch=$(get_main_branch)
        git worktree add -b "$branch" "$worktree_path" "$main_branch"
    fi
    
    # Copy config files if requested
    if [[ "$copy_configs" == "true" ]]; then
        local config_files=()
        
        if [[ -n "$custom_config_files" ]]; then
            # Parse custom config files (comma-separated)
            IFS=',' read -ra config_files <<< "$custom_config_files"
        else
            # Load from config file or use defaults
            while IFS= read -r file; do
                [[ -z "$file" ]] && continue
                config_files+=("$file")
            done < <(load_config_files)
        fi
        
        if [[ ${#config_files[@]} -gt 0 ]]; then
            copy_config_files "$worktree_path" "${config_files[@]}"
        fi
    fi
    
    log_success "Worktree created at: $worktree_path"
    log_info "To switch to this worktree: cd '$worktree_path'"
}

# List all worktrees
list_worktrees() {
    log_info "Current worktrees:"
    git worktree list --porcelain | awk '
    BEGIN { 
        printf "%-50s %-20s %-10s %s\n", "PATH", "BRANCH", "COMMIT", "STATUS"
        printf "%-50s %-20s %-10s %s\n", "----", "------", "------", "------"
    }
    /^worktree/ { path = substr($0, 10) }
    /^HEAD/ { commit = substr($0, 6, 7) }
    /^branch/ { branch = substr($0, 8) }
    /^bare/ { bare = "bare" }
    /^detached/ { detached = "detached" }
    /^locked/ { locked = "locked" }
    /^prunable/ { prunable = "prunable" }
    /^$/ { 
        status = ""
        if (bare) status = status "bare "
        if (detached) status = status "detached "
        if (locked) status = status "locked "
        if (prunable) status = status "prunable "
        if (status == "") status = "clean"
        
        printf "%-50s %-20s %-10s %s\n", path, (branch ? branch : "N/A"), commit, status
        path = branch = commit = bare = detached = locked = prunable = ""
    }'
}

# Remove worktree
remove_worktree() {
    local target="$1"
    local force="$2"
    
    if [[ -z "$target" ]]; then
        log_error "Worktree path or branch name required"
        exit 1
    fi
    
    # If target looks like a path
    if [[ "$target" == *"/"* ]] || [[ -d "$target" ]]; then
        local worktree_path="$target"
    else
        # Try to find worktree by branch name
        local worktree_path=$(git worktree list --porcelain | awk -v branch="$target" '
            /^worktree/ { path = substr($0, 10) }
            /^branch/ && substr($0, 8) == "refs/heads/" branch { print path; exit }
        ')
        
        if [[ -z "$worktree_path" ]]; then
            log_error "No worktree found for branch '$target'"
            exit 1
        fi
    fi
    
    log_info "Removing worktree at: $worktree_path"
    
    if [[ "$force" == "true" ]]; then
        git worktree remove --force "$worktree_path"
    else
        git worktree remove "$worktree_path"
    fi
    
    log_success "Worktree removed: $worktree_path"
}

# Clean up stale worktrees
cleanup_worktrees() {
    local force="$1"
    
    log_info "Cleaning up stale worktrees..."
    
    # First, prune worktree references
    git worktree prune --verbose
    
    # Find and optionally remove orphaned directories
    local orphaned_dirs=()
    
    # Get list of current worktrees
    local current_worktrees=$(git worktree list --porcelain | grep '^worktree' | cut -d' ' -f2-)
    
    # Check for directories that look like worktrees but aren't registered
    if [[ -d "$DEFAULT_BASE_DIR" ]]; then
        while IFS= read -r -d '' dir; do
            local dirname=$(basename "$dir")
            local project_name=$(basename "$PROJECT_ROOT")
            
            # Check if directory name matches our naming pattern
            if [[ "$dirname" == "$project_name-"* ]]; then
                # Check if it's in current worktrees list
                local found=false
                while IFS= read -r worktree; do
                    if [[ "$dir" == "$worktree" ]]; then
                        found=true
                        break
                    fi
                done <<< "$current_worktrees"
                
                if [[ "$found" == "false" ]]; then
                    orphaned_dirs+=("$dir")
                fi
            fi
        done < <(find "$DEFAULT_BASE_DIR" -maxdepth 1 -type d -print0 2>/dev/null)
    fi
    
    if [[ ${#orphaned_dirs[@]} -eq 0 ]]; then
        log_success "No orphaned worktree directories found"
        return
    fi
    
    log_warning "Found ${#orphaned_dirs[@]} potentially orphaned directories:"
    for dir in "${orphaned_dirs[@]}"; do
        echo "  - $dir"
    done
    
    if [[ "$force" == "true" ]]; then
        for dir in "${orphaned_dirs[@]}"; do
            log_info "Removing orphaned directory: $dir"
            rm -rf "$dir"
        done
        log_success "Cleaned up ${#orphaned_dirs[@]} orphaned directories"
    else
        echo
        read -p "Remove these directories? [y/N]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            for dir in "${orphaned_dirs[@]}"; do
                log_info "Removing orphaned directory: $dir"
                rm -rf "$dir"
            done
            log_success "Cleaned up ${#orphaned_dirs[@]} orphaned directories"
        else
            log_info "Cleanup cancelled"
        fi
    fi
}

# Switch to worktree
switch_worktree() {
    local branch="$1"
    
    if [[ -z "$branch" ]]; then
        log_error "Branch name required"
        exit 1
    fi
    
    # Find worktree for branch
    local worktree_path=$(git worktree list --porcelain | awk -v branch="$branch" '
        /^worktree/ { path = substr($0, 10) }
        /^branch/ && substr($0, 8) == "refs/heads/" branch { print path; exit }
    ')
    
    if [[ -z "$worktree_path" ]]; then
        log_error "No worktree found for branch '$branch'"
        log_info "Available worktrees:"
        list_worktrees
        exit 1
    fi
    
    log_success "Switching to worktree: $worktree_path"
    cd "$worktree_path"
    exec "${SHELL:-/bin/bash}"
}

# Show status of all worktrees
show_status() {
    log_info "Worktree status overview:"
    
    git worktree list --porcelain | awk '
    /^worktree/ { 
        path = substr($0, 10)
        if (path != "") {
            print "\n=== " path " ==="
            system("cd \"" path "\" 2>/dev/null && git status --short --branch || echo \"Error: Cannot access worktree\"")
        }
    }'
}

# Parse command line arguments
COMMAND=""
BRANCH=""
CUSTOM_PATH=""
BASE_DIR="$DEFAULT_BASE_DIR"
PREFIX="$WORKTREE_PREFIX"
FORCE=false
VERBOSE=false
COPY_CONFIGS=true
CUSTOM_CONFIG_FILES=""
CONFIG_ACTION=""
CONFIG_VALUE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        create|list|remove|cleanup|switch|status|prune|help)
            COMMAND="$1"
            shift
            ;;
        config)
            COMMAND="config"
            shift
            ;;
        -d|--base-dir)
            BASE_DIR="$2"
            shift 2
            ;;
        -p|--prefix)
            PREFIX="$2"
            shift 2
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -c|--copy-configs)
            COPY_CONFIGS=true
            shift
            ;;
        --no-copy-configs)
            COPY_CONFIGS=false
            shift
            ;;
        --config-files)
            CUSTOM_CONFIG_FILES="$2"
            shift 2
            ;;
        --list|--add|--remove|--reset)
            if [[ "$COMMAND" == "config" ]]; then
                CONFIG_ACTION="$1"
                shift
            else
                log_error "Config option $1 can only be used with 'config' command"
                exit 1
            fi
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            if [[ "$COMMAND" == "config" ]] && [[ -z "$CONFIG_VALUE" ]] && [[ -n "$CONFIG_ACTION" ]]; then
                CONFIG_VALUE="$1"
            elif [[ -z "$BRANCH" ]]; then
                BRANCH="$1"
            elif [[ -z "$CUSTOM_PATH" ]] && [[ "$COMMAND" == "create" ]]; then
                CUSTOM_PATH="$1"
            else
                log_error "Unknown argument: $1"
                usage
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate git repository
validate_git_repo

# Execute command
case "$COMMAND" in
    create)
        create_worktree "$BRANCH" "$CUSTOM_PATH" "$BASE_DIR" "$PREFIX" "$FORCE" "$COPY_CONFIGS" "$CUSTOM_CONFIG_FILES"
        ;;
    list)
        list_worktrees
        ;;
    remove)
        remove_worktree "$BRANCH" "$FORCE"
        ;;
    cleanup)
        cleanup_worktrees "$FORCE"
        ;;
    switch)
        switch_worktree "$BRANCH"
        ;;
    status)
        show_status
        ;;
    prune)
        log_info "Pruning worktree references..."
        git worktree prune --verbose
        log_success "Pruning complete"
        ;;
    config)
        if [[ -z "$CONFIG_ACTION" ]]; then
            CONFIG_ACTION="--list"
        fi
        manage_config "$CONFIG_ACTION" "$CONFIG_VALUE"
        ;;
    help)
        usage
        ;;
    "")
        log_error "No command specified"
        usage
        exit 1
        ;;
    *)
        log_error "Unknown command: $COMMAND"
        usage
        exit 1
        ;;
esac