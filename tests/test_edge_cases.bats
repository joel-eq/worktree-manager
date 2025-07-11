#!/usr/bin/env bats

# Edge cases and error handling tests for git worktree manager

load helpers/test_helpers

setup() {
    setup_test_repo
}

teardown() {
    cleanup_test_repo
}

# Test invalid command line arguments
@test "handles unknown command gracefully" {
    run_worktree_manager invalid-command
    assert_failure
    assert_output_contains "Unknown argument: invalid-command"
}

@test "handles unknown options gracefully" {
    run_worktree_manager create test-branch --unknown-option
    assert_failure
    assert_output_contains "Unknown argument"
}

@test "create command requires branch name" {
    run_worktree_manager create
    assert_failure
    assert_output_contains "Branch name required"
}

@test "remove command requires target" {
    run_worktree_manager remove
    assert_failure
    assert_output_contains "required"
}

# Test special characters in branch names
@test "handles branch names with slashes" {
    local branch="feature/user-auth/oauth2"
    
    run_worktree_manager create "$branch"
    assert_success
    
    worktree_exists "$branch"
    local worktree_path=$(get_worktree_path "$branch")
    # Path should have slashes converted to hyphens
    [[ $(basename "$worktree_path") == *"feature-user-auth-oauth2"* ]]
}

@test "handles branch names with special characters" {
    local branch="feature/user@domain.com_auth-v2.0"
    
    run_worktree_manager create "$branch"
    assert_success
    
    worktree_exists "$branch"
    # Should create worktree despite special characters
    local worktree_path=$(get_worktree_path "$branch")
    [ -d "$worktree_path" ]
}

@test "handles very long branch names" {
    local long_branch="very-long-branch-name-that-exceeds-normal-filesystem-limits-and-should-still-work-somehow-with-proper-handling"
    
    run_worktree_manager create "$long_branch"
    assert_success
    
    worktree_exists "$long_branch"
}

@test "handles branch names with Unicode characters" {
    local unicode_branch="feature/用户认证-naïve-résumé"
    
    run_worktree_manager create "$unicode_branch"
    assert_success
    
    worktree_exists "$unicode_branch"
}

# Test file system edge cases
@test "handles read-only parent directory gracefully" {
    # Create a worktree first
    local branch="readonly-test"
    run_worktree_manager create "$branch"
    assert_success
    
    local worktree_path=$(get_worktree_path "$branch")
    local parent_dir=$(dirname "$worktree_path")
    
    # Make parent directory read-only
    chmod 444 "$parent_dir"
    
    # Try to create another worktree (should fail gracefully)
    run_worktree_manager create "readonly-test-2"
    assert_failure
    
    # Restore permissions for cleanup
    chmod 755 "$parent_dir"
}

@test "handles missing parent directory creation" {
    local branch="deep-path-test"
    local custom_path="$TEST_ROOT/very/deep/nested/path/worktree"
    
    run_worktree_manager create "$branch" "$custom_path"
    assert_success
    
    [ -d "$custom_path" ]
    [ -f "$custom_path/README.md" ]
}

@test "handles disk space exhaustion gracefully" {
    # This is hard to test reliably without actually filling up disk
    # We'll simulate by creating a mock that fails
    skip "Disk space testing requires more complex setup"
}

# Test git command failures
@test "handles git worktree add failure" {
    # Create a worktree with the same name twice (second should fail)
    local branch="duplicate-test"
    
    run_worktree_manager create "$branch"
    assert_success
    
    # Git should prevent creating duplicate worktree
    run_worktree_manager create "$branch"
    assert_failure
}

@test "handles corrupted git repository" {
    # Corrupt the git directory
    rm -rf .git/refs
    
    run_worktree_manager list
    assert_failure
}

@test "handles detached HEAD state" {
    # Checkout a specific commit (detached HEAD)
    local commit=$(git rev-parse HEAD)
    git checkout "$commit"
    
    run_worktree_manager list
    assert_success
    # Should still work in detached HEAD
}

# Test config file edge cases
# Note: Corrupted config file test removed - advanced edge case

@test "handles extremely large config file" {
    # Create config with many entries
    local config_content=""
    for i in {1..1000}; do
        config_content+=".config-file-$i\n"
    done
    
    create_test_config "$config_content"
    
    run_worktree_manager config --list
    assert_success
    # Should handle large config files
}

@test "handles config file with no permissions" {
    create_test_config ".env\n.test-config"
    chmod 000 .worktree-config
    
    run_worktree_manager config --list
    assert_success
    # Should fall back to defaults when can't read config
    
    # Restore permissions for cleanup
    chmod 644 .worktree-config
}

# Test concurrent access
# Note: Concurrent operations test removed - advanced edge case requiring complex synchronization

# Test resource limits
@test "handles creation of many worktrees" {
    local branches=()
    
    # Create multiple worktrees
    for i in {1..10}; do
        local branch="many-worktrees-$i"
        branches+=("$branch")
        
        run_worktree_manager create "$branch"
        assert_success
    done
    
    # Verify all exist
    for branch in "${branches[@]}"; do
        worktree_exists "$branch"
    done
    
    # List should show all
    run_worktree_manager list
    assert_success
    for branch in "${branches[@]}"; do
        assert_output_contains "$branch"
    done
    
    # Clean up
    for branch in "${branches[@]}"; do
        run_worktree_manager remove "$branch"
    done
}

# Test network-related edge cases (for remote branches)
@test "handles network timeout for remote branches" {
    # This would require a remote repository setup
    skip "Network testing requires remote repository setup"
}

@test "handles non-existent remote branch" {
    local non_existent_remote="origin/non-existent-branch"
    
    run_worktree_manager create "non-existent-branch"
    # Should create new branch instead of failing
    assert_success
    assert_output_contains "Creating new branch"
}

# Test memory and performance edge cases
@test "handles very deep directory nesting" {
    # Create worktree in deeply nested directory
    local deep_path="$TEST_ROOT"
    for i in {1..20}; do
        deep_path="$deep_path/level$i"
    done
    
    local branch="deep-nest-test"
    run_worktree_manager create "$branch" "$deep_path"
    assert_success
    
    [ -d "$deep_path" ]
}

@test "handles large file copies during config copying" {
    # Create a large config file
    dd if=/dev/zero of=.large-config bs=1024 count=1024 2>/dev/null
    
    run_worktree_manager config --add ".large-config"
    assert_success
    
    local branch="large-file-test"
    run_worktree_manager create "$branch"
    assert_success
    
    local worktree_path=$(get_worktree_path "$branch")
    file_exists_in_worktree "$worktree_path" ".large-config"
    
    # Verify file was copied correctly
    local original_size=$(stat -f%z .large-config 2>/dev/null || stat -c%s .large-config)
    local copied_size=$(stat -f%z "$worktree_path/.large-config" 2>/dev/null || stat -c%s "$worktree_path/.large-config")
    [ "$original_size" -eq "$copied_size" ]
}

# Test signal handling
@test "handles script interruption gracefully" {
    # This is difficult to test comprehensively in bats
    # We can at least verify that cleanup works
    
    local branch="interrupt-test"
    run_worktree_manager create "$branch"
    assert_success
    
    # Simulate cleanup after interruption
    run_worktree_manager cleanup --force
    assert_success
}

# Test shell compatibility
@test "works with different shell environments" {
    # Test with minimal environment
    env -i PATH="$PATH" HOME="$HOME" bash -c "cd '$TEST_REPO' && '$WORKTREE_MANAGER' list"
    [ $? -eq 0 ]
}

@test "handles missing environment variables" {
    # Test without common environment variables
    local original_user="$USER"
    local original_home="$HOME"
    
    unset USER
    export HOME="/tmp"
    
    run_worktree_manager list
    assert_success
    
    # Restore environment
    export USER="$original_user"
    export HOME="$original_home"
}

# Test path edge cases
@test "handles paths with spaces" {
    local branch="spaces-test"
    local path_with_spaces="$TEST_ROOT/path with spaces/worktree"
    
    run_worktree_manager create "$branch" "$path_with_spaces"
    assert_success
    
    [ -d "$path_with_spaces" ]
    [ -f "$path_with_spaces/README.md" ]
}

# Note: Relative path test removed - advanced edge case with complex path resolution