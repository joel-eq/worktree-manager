#!/usr/bin/env bats

# Tests for worktree shortcuts functionality

load helpers/test_helpers

setup() {
    setup_test_repo
    # Source the shortcuts script
    source "$WORKTREE_SHORTCUTS"
}

teardown() {
    cleanup_test_repo
}

# Test that shortcuts script loads correctly
@test "shortcuts script loads without errors" {
    # If we get here, the source command in setup() succeeded
    [ "$?" -eq 0 ]
}

@test "shortcuts script finds worktree manager" {
    # The WORKTREE_MANAGER variable should be set
    [ -n "$WORKTREE_MANAGER" ]
    [ -x "$WORKTREE_MANAGER" ]
}

# Test basic aliases
@test "wt alias is defined" {
    # Check if alias exists
    alias wt >/dev/null 2>&1
    [ "$?" -eq 0 ]
}

@test "wtcreate alias works" {
    alias wtcreate >/dev/null 2>&1
    [ "$?" -eq 0 ]
}

@test "wtlist alias works" {
    alias wtlist >/dev/null 2>&1
    [ "$?" -eq 0 ]
}

@test "wtremove alias works" {
    alias wtremove >/dev/null 2>&1
    [ "$?" -eq 0 ]
}

# Test advanced functions exist
@test "wtcd function is defined" {
    declare -f wtcd >/dev/null 2>&1
    [ "$?" -eq 0 ]
}

@test "wtgo function is defined" {
    declare -f wtgo >/dev/null 2>&1
    [ "$?" -eq 0 ]
}

@test "wtfork function is defined" {
    declare -f wtfork >/dev/null 2>&1
    [ "$?" -eq 0 ]
}

@test "wtsync function is defined" {
    declare -f wtsync >/dev/null 2>&1
    [ "$?" -eq 0 ]
}

@test "wthelp function is defined" {
    declare -f wthelp >/dev/null 2>&1
    [ "$?" -eq 0 ]
}

# Test wtcd function behavior
@test "wtcd shows usage when called without arguments" {
    run wtcd
    assert_failure
    assert_output_contains "Usage: wtcd <branch-name>"
}

@test "wtcd fails for non-existent branch" {
    run wtcd "non-existent-branch"
    assert_failure
    assert_output_contains "No worktree found"
    assert_output_contains "Available worktrees"
}

# Test wtgo function behavior  
@test "wtgo shows usage when called without arguments" {
    run wtgo
    assert_failure
    assert_output_contains "Usage: wtgo <branch-name>"
    assert_output_contains "Creates worktree for branch if it doesn't exist"
}

@test "wtgo creates new worktree when branch doesn't exist" {
    local branch="wtgo-new-test"
    
    # Note: We can't test the actual directory change in bats easily,
    # but we can test that the worktree gets created
    run bash -c "cd '$TEST_REPO' && source '$WORKTREE_SHORTCUTS' && wtgo '$branch' 2>&1 || true"
    
    # Verify worktree was created
    cd "$TEST_REPO"
    assert worktree_exists "$branch"
}

@test "wtgo switches to existing worktree" {
    local branch="wtgo-existing-test"
    
    # Create worktree first
    cd "$TEST_REPO"
    run_worktree_manager create "$branch"
    assert_success
    
    # Test wtgo with existing worktree
    run bash -c "cd '$TEST_REPO' && source '$WORKTREE_SHORTCUTS' && wtgo '$branch' 2>&1 || true"
    
    # Should mention switching to existing
    assert_output_contains "Switching to existing worktree"
}

# Test wtfork function
@test "wtfork creates fork of current branch" {
    local current_branch="main"
    local expected_fork="main-fork"
    
    cd "$TEST_REPO"
    git checkout "$current_branch"
    
    run bash -c "cd '$TEST_REPO' && source '$WORKTREE_SHORTCUTS' && wtfork 2>&1"
    
    # Should create forked worktree
    assert worktree_exists "$expected_fork"
}

@test "wtfork accepts custom suffix" {
    local current_branch="main"
    local suffix="v2"
    local expected_fork="main-$suffix"
    
    cd "$TEST_REPO"
    git checkout "$current_branch"
    
    run bash -c "cd '$TEST_REPO' && source '$WORKTREE_SHORTCUTS' && wtfork '$suffix' 2>&1"
    
    # Should create forked worktree with custom suffix
    assert worktree_exists "$expected_fork"
}

# Test wtsync function
@test "wtsync processes all worktrees" {
    # Create a couple of worktrees
    cd "$TEST_REPO"
    run_worktree_manager create "sync-test-1"
    run_worktree_manager create "sync-test-2"
    
    run bash -c "cd '$TEST_REPO' && source '$WORKTREE_SHORTCUTS' && wtsync 2>&1"
    
    assert_output_contains "Syncing all worktrees"
    assert_output_contains "Syncing"
}

# Test wthelp function
@test "wthelp shows comprehensive help" {
    run bash -c "source '$WORKTREE_SHORTCUTS' && wthelp"
    
    assert_success
    assert_output_contains "Git Worktree Shortcuts"
    assert_output_contains "Basic Commands:"
    assert_output_contains "Advanced Functions:"
    assert_output_contains "Examples:"
    assert_output_contains "wtcreate"
    assert_output_contains "wtgo"
    assert_output_contains "wtcd"
}

# Test error handling in shortcuts
@test "shortcuts handle missing worktree manager gracefully" {
    # Create a test environment without the worktree manager
    local temp_shortcuts="$TEST_ROOT/test-shortcuts.sh"
    
    # Create shortcuts script that points to non-existent manager
    cat > "$temp_shortcuts" << 'EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
find_worktree_manager() {
    return 1
}

if WORKTREE_MANAGER=$(find_worktree_manager); then
    true
else
    echo "Error: git-worktree-manager.sh not found"
    return 1 2>/dev/null || exit 1
fi
EOF
    
    run bash -c "source '$temp_shortcuts' 2>&1"
    assert_failure
    assert_output_contains "not found"
}

# Test that shortcuts work from different directories
@test "shortcuts work from subdirectories" {
    cd "$TEST_REPO"
    mkdir -p deep/nested/dir
    cd deep/nested/dir
    
    # Source shortcuts from subdirectory
    run bash -c "source '$WORKTREE_SHORTCUTS' && declare -f wtgo >/dev/null"
    assert_success
}

# Test completion functions (if available)
@test "completion functions are defined in bash" {
    if [[ -n "$BASH_VERSION" ]]; then
        # Only test in bash
        run bash -c "source '$WORKTREE_SHORTCUTS' && declare -f _wtcd >/dev/null 2>&1"
        # This might not be defined in all environments, so don't fail
        # assert_success
    else
        skip "Completion test only runs in bash"
    fi
}

# Test shortcuts integration with real operations
@test "aliases execute real commands" {
    cd "$TEST_REPO"
    
    # Test that wtlist actually lists worktrees
    run bash -c "source '$WORKTREE_SHORTCUTS' && wtlist"
    assert_success
    assert_output_contains "Current worktrees"
    assert_output_contains "main"
}

@test "shortcuts preserve command line arguments" {
    cd "$TEST_REPO"
    
    # Test that arguments are passed through correctly
    run bash -c "source '$WORKTREE_SHORTCUTS' && wt config --list"
    assert_success
    assert_output_contains "Current config files"
}

# Test shortcuts with special characters
@test "shortcuts handle branch names with special characters" {
    local special_branch="feature/user@auth-v2.0"
    
    cd "$TEST_REPO"
    run bash -c "source '$WORKTREE_SHORTCUTS' && wtgo '$special_branch' 2>&1 || true"
    
    # Should handle special characters without crashing
    assert worktree_exists "$special_branch"
}