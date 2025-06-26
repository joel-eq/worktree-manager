#!/usr/bin/env bats

# Core functionality tests for git worktree manager

load helpers/test_helpers

setup() {
    setup_test_repo
}

teardown() {
    cleanup_test_repo
}

# Test script location and basic execution
@test "script exists and is executable" {
    [ -f "$WORKTREE_MANAGER" ]
    [ -x "$WORKTREE_MANAGER" ]
}

@test "script shows help when called with help command" {
    run_worktree_manager help
    assert_success
    assert_output_contains "Git Worktree Manager"
    assert_output_contains "Commands:"
    assert_output_contains "create"
    assert_output_contains "list"
    assert_output_contains "remove"
}

@test "script shows help when called with no arguments" {
    run_worktree_manager
    assert_failure
    assert_output_contains "No command specified"
}

# Test git root detection
@test "finds git root from repository root" {
    run_worktree_manager list
    assert_success
    assert_output_contains "Current worktrees:"
}

@test "finds git root from subdirectory" {
    mkdir -p src/deep/nested
    cd src/deep/nested
    
    run_worktree_manager list
    assert_success
    assert_output_contains "Current worktrees:"
}

@test "fails when run outside git repository" {
    cd "$TEST_ROOT"
    
    run_worktree_manager list
    assert_failure
    assert_output_contains "Not in a git repository"
}

# Test worktree listing
@test "lists existing worktrees" {
    run_worktree_manager list
    assert_success
    assert_output_contains "PATH"
    assert_output_contains "BRANCH"
    assert_output_contains "main"
}

@test "list command shows correct format" {
    run_worktree_manager list
    assert_success
    # Should show header and at least one worktree (main)
    assert_output_matches "PATH.*BRANCH.*COMMIT.*STATUS"
    assert_output_contains "refs/heads/main"
}

# Test worktree creation
@test "creates worktree for new branch" {
    local branch="test-new-branch"
    
    run_worktree_manager create "$branch"
    assert_success
    assert_output_contains "Creating new branch"
    assert_output_contains "Worktree created"
    
    # Verify worktree was created
    worktree_exists "$branch"
    
    local worktree_path=$(get_worktree_path "$branch")
    [ -d "$worktree_path" ]
    [ -f "$worktree_path/README.md" ]
}

@test "creates worktree for existing local branch" {
    local branch="feature/test-branch"
    
    run_worktree_manager create "$branch"
    assert_success
    assert_output_contains "Branch '$branch' exists locally"
    assert_output_contains "Worktree created"
    
    # Verify worktree was created
    worktree_exists "$branch"
    
    local worktree_path=$(get_worktree_path "$branch")
    [ -d "$worktree_path" ]
    [ -f "$worktree_path/feature.txt" ]
}

@test "creates worktree with custom path" {
    local branch="custom-path-test"
    local custom_path="$TEST_ROOT/custom-worktree"
    
    run_worktree_manager create "$branch" "$custom_path"
    assert_success
    assert_output_contains "Worktree created at: $custom_path"
    
    [ -d "$custom_path" ]
    [ -f "$custom_path/README.md" ]
}

@test "generates correct worktree path" {
    local branch="feature/auth-system"
    local expected_name="$(basename "$TEST_REPO")-feature-auth-system"
    
    run_worktree_manager create "$branch"
    assert_success
    
    local worktree_path=$(get_worktree_path "$branch")
    local actual_name=$(basename "$worktree_path")
    
    [ "$actual_name" = "$expected_name" ]
}

@test "handles special characters in branch names" {
    local branch="feature/user@auth-system_v2"
    
    run_worktree_manager create "$branch"
    assert_success
    
    # Should create worktree with sanitized directory name
    worktree_exists "$branch"
    local worktree_path=$(get_worktree_path "$branch")
    [ -d "$worktree_path" ]
}

@test "fails to create worktree when directory exists" {
    local branch="existing-dir-test"
    
    # Create the worktree first
    run_worktree_manager create "$branch"
    assert_success
    
    # Try to create again
    run_worktree_manager create "$branch"
    assert_failure
    assert_output_contains "already exists"
}

@test "creates worktree with force flag when directory exists" {
    local branch="force-test"
    local worktree_path="../$(basename "$TEST_REPO")-$branch"
    
    # Create directory first to simulate existing directory
    mkdir -p "$worktree_path"
    
    # Try to create worktree with force (should succeed)
    run_worktree_manager create "$branch" "$worktree_path" --force
    assert_success
}

# Test config file copying
@test "copies config files to new worktree by default" {
    local branch="config-copy-test"
    
    run_worktree_manager create "$branch"
    assert_success
    assert_output_contains "Copying config files"
    assert_output_contains "Copied"
    
    local worktree_path=$(get_worktree_path "$branch")
    file_exists_in_worktree "$worktree_path" ".env"
    file_exists_in_worktree "$worktree_path" ".mcp.json"
    file_exists_in_worktree "$worktree_path" ".taskmaster/config.json"
    file_exists_in_worktree "$worktree_path" ".vscode/settings.json"
}

@test "skips config copying when disabled" {
    local branch="no-config-test"
    
    # Create a config file that's NOT in git to test that it's not copied
    echo "custom content" > .env.custom
    
    run_worktree_manager create "$branch" --no-copy-configs
    assert_success
    
    local worktree_path=$(get_worktree_path "$branch")
    # Files that are in git will still exist (they're part of the worktree)
    file_exists_in_worktree "$worktree_path" ".env"
    file_exists_in_worktree "$worktree_path" ".mcp.json"
    # But files not in git should not be copied when config copying is disabled
    [ ! -f "$worktree_path/.env.custom" ]
}

@test "copies only specified config files" {
    local branch="custom-config-test"
    
    # Create a config file that's NOT in git to test selective copying
    echo "custom content" > .env.custom
    
    run_worktree_manager create "$branch" --config-files ".env,.env.custom"
    assert_success
    
    local worktree_path=$(get_worktree_path "$branch")
    file_exists_in_worktree "$worktree_path" ".env"
    file_exists_in_worktree "$worktree_path" ".env.custom"
    # .mcp.json should exist because it's in git, but we didn't request it to be copied by our config logic
    file_exists_in_worktree "$worktree_path" ".mcp.json"
}

# Test worktree removal
@test "removes worktree by branch name" {
    local branch="remove-test"
    
    # Create worktree
    run_worktree_manager create "$branch"
    assert_success
    worktree_exists "$branch"
    
    # Remove worktree
    run_worktree_manager remove "$branch" --force
    assert_success
    assert_output_contains "Worktree removed"
    
    # Verify removal
    ! worktree_exists "$branch"
}

@test "removes worktree by path" {
    local branch="remove-by-path-test"
    
    # Create worktree
    run_worktree_manager create "$branch"
    assert_success
    local worktree_path=$(get_worktree_path "$branch")
    
    # Remove by path
    run_worktree_manager remove "$worktree_path" --force
    assert_success
    assert_output_contains "Worktree removed"
    
    # Verify removal
    ! worktree_exists "$branch"
    [ ! -d "$worktree_path" ]
}

@test "fails to remove non-existent worktree" {
    run_worktree_manager remove "non-existent-branch"
    assert_failure
    assert_output_contains "No worktree found"
}

# Test worktree status
@test "shows status of all worktrees" {
    local branch="status-test"
    
    # Create a worktree
    run_worktree_manager create "$branch"
    assert_success
    
    # Check status
    run_worktree_manager status
    assert_success
    assert_output_contains "Worktree status overview"
}

# Test worktree switching
@test "switches to existing worktree" {
    local branch="switch-test"
    
    # Create worktree
    run_worktree_manager create "$branch"
    assert_success
    
    # We can't test the actual shell switching because it uses exec,
    # but we can verify the worktree exists and is found
    worktree_exists "$branch"
    
    local worktree_path=$(get_worktree_path "$branch")
    [ -d "$worktree_path" ]
}

# Test cleanup functionality
@test "prunes worktree references" {
    run_worktree_manager prune
    assert_success
    assert_output_contains "Pruning worktree references"
}

@test "cleanup detects orphaned directories" {
    local branch="cleanup-test"
    
    # Create worktree
    run_worktree_manager create "$branch"
    assert_success
    local worktree_path=$(get_worktree_path "$branch")
    
    # Manually remove worktree from git (simulating orphaned directory)
    git worktree remove --force "$worktree_path"
    
    # Recreate directory to simulate orphaned state
    mkdir -p "$worktree_path"
    
    # Test cleanup
    run_worktree_manager cleanup --force
    assert_success
    
    # Directory should be cleaned up
    [ ! -d "$worktree_path" ]
}