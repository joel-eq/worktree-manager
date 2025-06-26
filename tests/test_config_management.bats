#!/usr/bin/env bats

# Configuration management tests for git worktree manager

load helpers/test_helpers

setup() {
    setup_test_repo
}

teardown() {
    cleanup_test_repo
}

# Test config command basic functionality
@test "config command shows help with no arguments" {
    run_worktree_manager config
    assert_success
    assert_output_contains "Current config files to copy"
}

@test "config list shows default configuration" {
    run_worktree_manager config --list
    assert_success
    assert_output_contains "Current config files to copy"
    assert_output_contains ".env"
    assert_output_contains ".mcp.json"
    assert_output_contains ".taskmaster/config.json"
    assert_output_contains ".vscode/settings.json"
}

@test "config list shows file status correctly" {
    run_worktree_manager config --list
    assert_success
    # Files that exist should show ✓
    assert_output_contains "✓ .env"
    assert_output_contains "✓ .mcp.json"
    assert_output_contains "✓ .taskmaster/config.json"
    assert_output_contains "✓ .vscode/settings.json"
    # Files that don't exist should show -
    assert_output_contains "- .env.local (not found)"
}

# Test adding config files
@test "config add adds new file to configuration" {
    local new_file=".env.production"
    
    run_worktree_manager config --add "$new_file"
    assert_success
    assert_output_contains "Added '$new_file' to config files"
    
    # Verify it's in the list
    run_worktree_manager config --list
    assert_success
    assert_output_contains "$new_file"
}

@test "config add creates config file if it doesn't exist" {
    local new_file=".custom-config"
    
    run_worktree_manager config --add "$new_file"
    assert_success
    
    # Config file should be created
    [ -f "$TEST_REPO/.worktree-config" ]
    
    # Should contain the new file
    grep -q "$new_file" "$TEST_REPO/.worktree-config"
}

@test "config add prevents duplicate entries" {
    local existing_file=".env"
    
    run_worktree_manager config --add "$existing_file"
    assert_success
    assert_output_contains "already in config list"
    
    # Should still only appear once in config
    run_worktree_manager config --list
    assert_success
    local count=$(echo "$output" | grep -c ".env" || true)
    [ "$count" -eq 1 ]
}

@test "config add fails without file argument" {
    run_worktree_manager config --add
    assert_failure
    assert_output_contains "File path required for --add"
}

# Test removing config files
@test "config remove removes existing file" {
    local file_to_remove=".env"
    
    run_worktree_manager config --remove "$file_to_remove"
    assert_success
    assert_output_contains "Removed '$file_to_remove' from config files"
    
    # Verify it's not in the list
    run_worktree_manager config --list
    assert_success
    ! echo "$output" | grep -q "✓ $file_to_remove"
}

@test "config remove warns when file not found" {
    local non_existent=".non-existent-file"
    
    run_worktree_manager config --remove "$non_existent"
    assert_success
    assert_output_contains "not found in config list"
}

@test "config remove fails without file argument" {
    run_worktree_manager config --remove
    assert_failure
    assert_output_contains "File path required for --remove"
}

# Test config reset
@test "config reset restores defaults" {
    # Add a custom file
    run_worktree_manager config --add ".custom-file"
    assert_success
    
    # Remove a default file
    run_worktree_manager config --remove ".env"
    assert_success
    
    # Reset to defaults
    run_worktree_manager config --reset
    assert_success
    assert_output_contains "Reset config files to defaults"
    
    # Verify defaults are restored
    run_worktree_manager config --list
    assert_success
    assert_output_contains ".env"
    ! echo "$output" | grep -q ".custom-file"
}

# Test config file format and persistence
@test "config file has correct format" {
    run_worktree_manager config --add ".test-file"
    assert_success
    
    # Check config file format
    [ -f "$TEST_REPO/.worktree-config" ]
    
    # Should have header comments
    grep -q "# Worktree Manager Configuration" "$TEST_REPO/.worktree-config"
    grep -q "# Lines starting with # are comments" "$TEST_REPO/.worktree-config"
    
    # Should contain the test file
    grep -q ".test-file" "$TEST_REPO/.worktree-config"
}

@test "config persists across commands" {
    # Add a file
    run_worktree_manager config --add ".persistent-test"
    assert_success
    
    # Run another command that loads config
    run_worktree_manager config --list
    assert_success
    assert_output_contains ".persistent-test"
    
    # Create worktree and verify config is used
    local branch="persistence-test"
    echo "test content" > .persistent-test
    
    run_worktree_manager create "$branch"
    assert_success
    
    local worktree_path=$(get_worktree_path "$branch")
    assert file_exists_in_worktree "$worktree_path" ".persistent-test"
}

@test "config handles comments and empty lines" {
    # Create a config file with comments and empty lines
    create_test_config "# This is a comment
.env
# Another comment

.mcp.json
    # Indented comment
.custom-config
"
    
    run_worktree_manager config --list
    assert_success
    assert_output_contains ".env"
    assert_output_contains ".mcp.json"
    assert_output_contains ".custom-config"
    # Should not show comments as files
    ! echo "$output" | grep -q "This is a comment"
}

# Test config file loading with missing files
@test "config gracefully handles missing config file" {
    # Remove config file if it exists
    rm -f "$TEST_REPO/.worktree-config"
    
    run_worktree_manager config --list
    assert_success
    # Should show defaults
    assert_output_contains ".env"
    assert_output_contains ".mcp.json"
}

# Test config with worktree creation
@test "custom config affects worktree creation" {
    # Create custom config with only specific files
    create_test_config ".env
.custom-only"
    
    # Create the custom file
    echo "custom content" > .custom-only
    
    local branch="custom-config-test"
    run_worktree_manager create "$branch"
    assert_success
    
    local worktree_path=$(get_worktree_path "$branch")
    # Should copy files from custom config
    assert file_exists_in_worktree "$worktree_path" ".env"
    assert file_exists_in_worktree "$worktree_path" ".custom-only"
    
    # Should not copy files not in custom config
    [ ! -f "$worktree_path/.mcp.json" ]
    [ ! -f "$worktree_path/.taskmaster/config.json" ]
}

@test "config command-line override works" {
    # Set up custom config
    create_test_config ".env
.config-file-only"
    
    local branch="override-test"
    
    # Use command-line override
    run_worktree_manager create "$branch" --config-files ".env,.override-only"
    assert_success
    
    local worktree_path=$(get_worktree_path "$branch")
    # Should only copy command-line specified files
    assert file_exists_in_worktree "$worktree_path" ".env"
    [ ! -f "$worktree_path/.config-file-only" ]
    
    # Note: .override-only doesn't exist in source, so won't be copied
    # but the config system should try to copy it
}

# Test config with nested directories
@test "config handles nested directory paths" {
    run_worktree_manager config --add "config/app.json"
    assert_success
    
    # Create the nested config file
    mkdir -p config
    echo '{"app": "test"}' > config/app.json
    
    local branch="nested-config-test"
    run_worktree_manager create "$branch"
    assert_success
    
    local worktree_path=$(get_worktree_path "$branch")
    assert file_exists_in_worktree "$worktree_path" "config/app.json"
}

# Test edge cases
@test "config handles empty file paths gracefully" {
    # This should not crash or add empty entries
    run_worktree_manager config --add ""
    assert_failure
}

@test "config handles whitespace in file paths" {
    local file_with_spaces="config with spaces.json"
    
    run_worktree_manager config --add "$file_with_spaces"
    assert_success
    
    run_worktree_manager config --list
    assert_success
    assert_output_contains "$file_with_spaces"
}