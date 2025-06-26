#!/usr/bin/env bash

# Test helpers for git worktree manager tests

# Colors for test output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global test variables
export SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export WORKTREE_MANAGER="$SCRIPT_DIR/git-worktree-manager.sh"
export WORKTREE_SHORTCUTS="$SCRIPT_DIR/worktree-shortcuts.sh"

# Test repository setup
setup_test_repo() {
    # Create temporary test directory
    export TEST_ROOT=$(mktemp -d -t worktree-test-XXXXXX)
    export TEST_REPO="$TEST_ROOT/test-repo"
    
    # Create git repository
    mkdir -p "$TEST_REPO"
    cd "$TEST_REPO"
    
    git init
    git config user.email "test@example.com"
    git config user.name "Test User"
    
    # Create initial commit
    echo "# Test Repository" > README.md
    echo "test content" > file1.txt
    git add README.md file1.txt
    git commit -m "Initial commit"
    
    # Create some sample config files
    echo "DATABASE_URL=test://localhost" > .env
    echo "DEBUG=true" > .env.local
    echo '{"api_key": "test"}' > .mcp.json
    mkdir -p .taskmaster
    echo '{"model": "test"}' > .taskmaster/config.json
    mkdir -p .vscode
    echo '{"editor.tabSize": 2}' > .vscode/settings.json
    
    # Add config files to git
    git add .env .mcp.json .taskmaster/config.json .vscode/settings.json
    git commit -m "Add config files"
    
    # Create a feature branch
    git checkout -b feature/test-branch
    echo "feature content" > feature.txt
    git add feature.txt
    git commit -m "Add feature"
    git checkout main
    
    echo "Test repo created at: $TEST_REPO" >&3
}

# Clean up test repository
cleanup_test_repo() {
    if [[ -n "$TEST_ROOT" && -d "$TEST_ROOT" ]]; then
        # Clean up any worktrees first
        cd "$TEST_REPO" 2>/dev/null || true
        git worktree list --porcelain 2>/dev/null | grep "^worktree" | cut -d' ' -f2- | while read -r worktree_path; do
            if [[ "$worktree_path" != "$TEST_REPO" ]]; then
                git worktree remove --force "$worktree_path" 2>/dev/null || true
            fi
        done
        
        # Remove test directory
        rm -rf "$TEST_ROOT"
        echo "Test repo cleaned up" >&3
    fi
}

# Check if a worktree exists
worktree_exists() {
    local branch="$1"
    git worktree list --porcelain | grep -q "branch refs/heads/$branch"
}

# Get worktree path for branch
get_worktree_path() {
    local branch="$1"
    git worktree list --porcelain | awk -v branch="$branch" '
        /^worktree/ { path = substr($0, 10) }
        /^branch/ && substr($0, 8) == "refs/heads/" branch { print path; exit }
    '
}

# Count number of worktrees
count_worktrees() {
    git worktree list --porcelain | grep -c "^worktree"
}

# Check if file exists in worktree
file_exists_in_worktree() {
    local worktree_path="$1"
    local file_path="$2"
    [[ -f "$worktree_path/$file_path" ]]
}

# Assert file contents match
assert_file_content() {
    local file_path="$1"
    local expected_content="$2"
    local actual_content
    
    if [[ ! -f "$file_path" ]]; then
        echo "File does not exist: $file_path" >&2
        return 1
    fi
    
    actual_content=$(cat "$file_path")
    if [[ "$actual_content" != "$expected_content" ]]; then
        echo "File content mismatch:" >&2
        echo "Expected: $expected_content" >&2
        echo "Actual: $actual_content" >&2
        return 1
    fi
}

# Run worktree manager command and capture output
run_worktree_manager() {
    run "$WORKTREE_MANAGER" "$@"
}

# Check if command succeeded
assert_success() {
    if [[ "$status" -ne 0 ]]; then
        echo "Command failed with status $status" >&2
        echo "Output: $output" >&2
        return 1
    fi
}

# Check if command failed
assert_failure() {
    if [[ "$status" -eq 0 ]]; then
        echo "Command succeeded when it should have failed" >&2
        echo "Output: $output" >&2
        return 1
    fi
}

# Check if output contains string
assert_output_contains() {
    local expected="$1"
    if [[ "$output" != *"$expected"* ]]; then
        echo "Output does not contain: $expected" >&2
        echo "Actual output: $output" >&2
        return 1
    fi
}

# Check if output matches pattern
assert_output_matches() {
    local pattern="$1"
    if [[ ! "$output" =~ $pattern ]]; then
        echo "Output does not match pattern: $pattern" >&2
        echo "Actual output: $output" >&2
        return 1
    fi
}

# Create a test config file
create_test_config() {
    local config_content="$1"
    echo "$config_content" > "$TEST_REPO/.worktree-config"
}

# Simulate git command failure by creating a mock git script
mock_git_failure() {
    local command="$1"
    local temp_bin="$TEST_ROOT/mock-bin"
    mkdir -p "$temp_bin"
    
    cat > "$temp_bin/git" << EOF
#!/bin/bash
if [[ "\$1" == "$command" ]]; then
    echo "Mock git $command failure" >&2
    exit 1
fi
exec /usr/bin/git "\$@"
EOF
    chmod +x "$temp_bin/git"
    export PATH="$temp_bin:$PATH"
}

# Restore normal git
restore_git() {
    export PATH="${PATH#*/mock-bin:}"
}

# Print test section header
test_section() {
    local section_name="$1"
    echo -e "${BLUE}=== $section_name ===${NC}" >&3
}

# Print test info
test_info() {
    local message="$1"
    echo -e "${GREEN}INFO:${NC} $message" >&3
}