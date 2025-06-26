# Testing Guide for Git Worktree Manager

Comprehensive test suite using Bats (Bash Automated Testing System) to ensure reliability and catch regressions.

## Running Tests

### Quick Test Run
```bash
# Run all tests
./run_tests.sh

# Run with verbose output
./run_tests.sh --verbose

# Run specific test file
./run_tests.sh --test test_core_functionality.bats
```

### Install Bats (if needed)
```bash
# macOS
brew install bats-core

# Ubuntu/Debian
sudo apt-get install bats

# npm
npm install -g bats

# Docker (no installation needed)
docker run --rm -v "$PWD":/code bats/bats:latest /code/tests
```

## Test Structure

### Test Files
- **`test_core_functionality.bats`** - Main features (create, list, remove, config copying)
- **`test_config_management.bats`** - Configuration file management
- **`test_edge_cases.bats`** - Error handling, special characters, edge cases
- **`test_shortcuts.bats`** - Shell aliases and convenience functions

### Helper Functions
- **`tests/helpers/test_helpers.bash`** - Shared test utilities
  - Test repository setup/cleanup
  - Git operation helpers
  - Assertion functions
  - Mock utilities

## Test Categories

### Core Functionality Tests
✅ Script execution and help display  
✅ Git root detection from any directory  
✅ Worktree creation (new, existing, remote branches)  
✅ Worktree listing and status display  
✅ Worktree removal by name or path  
✅ Config file copying to new worktrees  
✅ Directory path generation and sanitization  

### Configuration Management Tests
✅ Config file list/add/remove operations  
✅ Default configuration handling  
✅ Custom config file persistence  
✅ Config file format validation  
✅ Command-line config overrides  

### Edge Case Tests
✅ Special characters in branch names  
✅ Unicode and international characters  
✅ Very long branch names  
✅ Invalid command line arguments  
✅ File system permission issues  
✅ Corrupted git repositories  
✅ Missing dependencies  
✅ Large file handling  

### Integration Tests
✅ Shell shortcuts functionality  
✅ Multi-worktree scenarios  
✅ Cross-platform compatibility  
✅ Git command failure handling  

## Writing New Tests

### Basic Test Structure
```bash
#!/usr/bin/env bats

load helpers/test_helpers

setup() {
    setup_test_repo
}

teardown() {
    cleanup_test_repo
}

@test "descriptive test name" {
    # Arrange
    local branch="test-branch"
    
    # Act
    run_worktree_manager create "$branch"
    
    # Assert
    assert_success
    assert_output_contains "Worktree created"
    assert worktree_exists "$branch"
}
```

### Available Assertions
```bash
# Command execution
assert_success              # Command succeeded (exit code 0)
assert_failure              # Command failed (exit code != 0)

# Output checking
assert_output_contains "text"     # Output contains string
assert_output_matches "pattern"   # Output matches regex

# File operations
assert file_exists_in_worktree "$path" "$file"
assert_file_content "$file" "$expected"

# Git operations
assert worktree_exists "$branch"
worktree_path=$(get_worktree_path "$branch")
count=$(count_worktrees)
```

### Test Helpers
```bash
# Repository management
setup_test_repo           # Creates temp git repo with sample files
cleanup_test_repo         # Removes temp repo and worktrees
create_test_config "$content"  # Creates .worktree-config file

# Mocking
mock_git_failure "command"     # Mock git command failures
restore_git                    # Restore normal git

# Utilities
test_section "Section Name"    # Print test section header
test_info "message"           # Print test info message
```

## Test Environment

### Temporary Directories
Each test gets a fresh temporary directory:
- `$TEST_ROOT` - Temporary test root directory
- `$TEST_REPO` - Git repository for testing
- Automatic cleanup after each test

### Isolation
- Tests don't affect your real git repositories
- Each test runs in isolated environment
- No interference between tests
- Safe to run multiple times

### Sample Data
Test repositories include:
- Initial commit with README.md and files
- Sample config files (.env, .mcp.json, etc.)
- Feature branch with additional content
- Realistic project structure

## Continuous Integration

### GitHub Actions Example
```yaml
name: Test Worktree Manager
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: Install Bats
      run: sudo apt-get install bats
    - name: Run Tests
      run: ./worktree-manager/run_tests.sh
```

### Docker Testing
```bash
# Test in clean environment
docker run --rm -v "$PWD":/workspace -w /workspace/worktree-manager \
  ubuntu:latest bash -c "
    apt-get update && 
    apt-get install -y git bats &&
    ./run_tests.sh
  "
```

## Performance Testing

### Large Scale Tests
Some tests create multiple worktrees to test:
- Memory usage with many worktrees
- Performance with large config files
- Cleanup efficiency
- File system limits

### Benchmarking
```bash
# Time test execution
time ./run_tests.sh

# Memory usage monitoring
/usr/bin/time -l ./run_tests.sh  # macOS
/usr/bin/time -v ./run_tests.sh  # Linux
```

## Debugging Tests

### Verbose Output
```bash
# Show detailed test execution
./run_tests.sh --verbose

# Debug specific test
bats --verbose-run tests/test_core_functionality.bats
```

### Manual Debugging
```bash
# Run test setup manually
source tests/helpers/test_helpers.bash
setup_test_repo
cd "$TEST_REPO"

# Debug interactively
./git-worktree-manager.sh create debug-branch
ls -la ../
git worktree list
```

### Test Artifacts
Failed tests leave artifacts in `/tmp/worktree-test-*` for inspection:
- Test git repositories
- Generated worktrees
- Config files
- Error logs

## Contributing Tests

### Test Guidelines
1. **Descriptive names** - Clearly describe what's being tested
2. **Arrange-Act-Assert** - Structure tests clearly
3. **Independent tests** - No dependencies between tests
4. **Clean up** - Always clean up test artifacts
5. **Edge cases** - Test boundary conditions
6. **Error cases** - Test failure scenarios

### Adding New Test Files
1. Create `test_feature_name.bats` in `tests/` directory
2. Follow naming convention: `test_*.bats`
3. Load test helpers: `load helpers/test_helpers`
4. Add setup/teardown functions
5. Write descriptive test cases

### Submitting Tests
- Include tests with new features
- Ensure all tests pass
- Add documentation for new test helpers
- Update this guide if needed

Run `./run_tests.sh` before submitting changes to ensure all tests pass!