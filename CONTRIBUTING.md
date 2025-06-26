# Contributing to Git Worktree Manager

Thank you for your interest in contributing! This guide will help you get started with contributing to the Git Worktree Manager project.

## 🚀 Quick Start

1. **Fork the repository** on GitHub
2. **Clone your fork** locally
3. **Run tests** to ensure everything works
4. **Make your changes**
5. **Add tests** for your changes
6. **Submit a pull request**

```bash
# Clone your fork
git clone https://github.com/yourusername/git-worktree-manager.git
cd git-worktree-manager

# Run tests to verify setup
./run_tests.sh

# Create feature branch
git checkout -b feature/my-awesome-feature

# Make changes and test
./git-worktree-manager.sh help
./run_tests.sh

# Commit and push
git commit -m "Add awesome feature"
git push origin feature/my-awesome-feature
```

## 📋 Development Guidelines

### Code Style

**Shell Script Standards:**
- Use `bash` shebang: `#!/bin/bash`
- Set strict mode: `set -e`
- Use meaningful variable names
- Quote variables: `"$variable"`
- Use local variables in functions: `local var_name`
- Follow the existing indentation (2 spaces)

**Function Documentation:**
```bash
# Brief description of what function does
function_name() {
    local param1="$1"
    local param2="$2"
    
    # Implementation
}
```

**Error Handling:**
```bash
# Check for required parameters
if [[ -z "$param" ]]; then
    log_error "Parameter required"
    exit 1
fi

# Handle command failures gracefully
if ! git worktree add "$path" "$branch"; then
    log_error "Failed to create worktree"
    return 1
fi
```

### Testing Requirements

**All contributions must include tests:**
- Add tests for new functionality
- Update tests for modified functionality
- Ensure all tests pass before submitting
- Test edge cases and error conditions

**Writing Tests:**
```bash
@test "descriptive test name" {
    # Arrange
    local test_data="example"
    
    # Act
    run_worktree_manager command "$test_data"
    
    # Assert
    assert_success
    assert_output_contains "expected result"
}
```

**Test Categories:**
- **Core functionality tests** - Main features
- **Configuration tests** - Config management
- **Edge case tests** - Error handling, special inputs
- **Integration tests** - Shell shortcuts, workflows

### Documentation Standards

**Update documentation when:**
- Adding new commands or options
- Changing existing behavior
- Adding new configuration options
- Fixing bugs that affect documented behavior

**Documentation files to consider:**
- `README.md` - Main project documentation
- `INSTALL.md` - Installation instructions
- `TESTING.md` - Testing information
- `CHANGELOG.md` - Version history
- Inline code comments for complex logic

## 🔧 Development Setup

### Prerequisites
- **Git 2.5+** with worktree support
- **Bash 4.0+** (or compatible shell)
- **Bats** testing framework
- **ShellCheck** for linting (recommended)

### Install Development Tools

```bash
# macOS
brew install bats-core shellcheck

# Ubuntu/Debian
sudo apt-get install bats shellcheck

# Verify installation
bats --version
shellcheck --version
```

### Running Tests Locally

```bash
# Run all tests
./run_tests.sh

# Run specific test file
./run_tests.sh --test test_core_functionality.bats

# Run with verbose output
./run_tests.sh --verbose

# Lint shell scripts
shellcheck git-worktree-manager.sh
shellcheck worktree-shortcuts.sh
```

### Debugging

```bash
# Debug test setup
source tests/helpers/test_helpers.bash
setup_test_repo
cd "$TEST_REPO"

# Test commands manually
./git-worktree-manager.sh create debug-branch
git worktree list
```

## 📝 Contribution Types

### 🐛 Bug Fixes
1. **Reproduce the bug** with a minimal test case
2. **Write a test** that demonstrates the bug
3. **Fix the bug** ensuring the test passes
4. **Verify** no other tests are broken

### ✨ New Features
1. **Discuss the feature** in an issue first
2. **Design the interface** (commands, options)
3. **Implement incrementally** with tests
4. **Update documentation** and examples

### 📖 Documentation
1. **Identify gaps** or unclear sections
2. **Write clear, concise explanations**
3. **Include practical examples**
4. **Test examples actually work**

### 🧪 Testing
1. **Identify untested scenarios**
2. **Write comprehensive test cases**
3. **Test edge cases and error conditions**
4. **Ensure tests are reliable and fast**

## 🚦 Pull Request Process

### Before Submitting
- [ ] All tests pass locally
- [ ] Code follows style guidelines
- [ ] Documentation is updated
- [ ] Commit messages are clear
- [ ] No merge conflicts with main branch

### Pull Request Checklist
- [ ] **Clear title** describing the change
- [ ] **Description** explaining what and why
- [ ] **Tests added** for new functionality
- [ ] **Documentation updated** if needed
- [ ] **Breaking changes** noted in description

### PR Template
```markdown
## Summary
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Refactoring

## Testing
- [ ] All existing tests pass
- [ ] New tests added
- [ ] Manual testing completed

## Documentation
- [ ] README updated
- [ ] Help text updated
- [ ] Examples added/updated
```

## 🎯 Areas for Contribution

### High Priority
- **Performance improvements** for large repositories
- **Windows compatibility** improvements
- **Error message clarity** and user experience
- **Additional test coverage** for edge cases

### Medium Priority
- **Integration with popular tools** (VS Code, IntelliJ)
- **Configuration templates** for common setups
- **Bulk operations** on multiple worktrees
- **Git hooks integration**

### Nice to Have
- **GUI wrapper** or web interface
- **Docker integration** for containerized development
- **Remote repository cloning** for worktrees
- **Worktree templates** and scaffolding

## 📞 Getting Help

### Communication Channels
- **GitHub Issues** - Bug reports and feature requests
- **GitHub Discussions** - Questions and general discussion
- **Pull Request Reviews** - Code review and feedback

### Common Questions

**Q: How do I test my changes?**
A: Run `./run_tests.sh` to execute the full test suite. Add new tests in the appropriate `test_*.bats` file.

**Q: What shell versions should I target?**
A: Bash 4.0+ is the primary target, with macOS bash 3.2 compatibility when possible.

**Q: How do I add a new command?**
A: 1) Add the command to the usage function, 2) Add case in the command execution section, 3) Implement the function, 4) Add tests.

**Q: Should I update the changelog?**
A: Yes, add an entry to `CHANGELOG.md` under "Unreleased" section.

## 🏆 Recognition

Contributors will be:
- Listed in project acknowledgments
- Credited in release notes for significant contributions
- Invited to be maintainers for sustained contributions

## 📄 License

By contributing, you agree that your contributions will be licensed under the same MIT License that covers the project.