# Changelog

All notable changes to the Git Worktree Manager will be documented in this file.

## [1.0.0] - 2025-06-25

### Added
- **Core worktree management**
  - Create worktrees for new, existing local, and remote branches
  - List all worktrees with detailed status information
  - Remove worktrees by branch name or path
  - Clean up orphaned worktrees and stale references
  - Switch between worktrees with new shell session

- **Automatic config file copying**
  - Copy important config files (.env, .mcp.json, etc.) to new worktrees
  - Configurable list of files to copy
  - Support for nested directory structures
  - Skip copying for specific worktrees when needed

- **Configuration management**
  - Manage config files via `config` command
  - Add/remove files from copy list
  - Reset to sensible defaults
  - Persistent configuration in `.worktree-config`

- **Smart git integration**
  - Automatic git root detection from any directory within repository
  - Works with local, remote, and new branches
  - Handles special characters in branch names
  - Generates clean directory names from branch names

- **Shell shortcuts and aliases**
  - Convenient aliases: `wt`, `wtcreate`, `wtlist`, `wtremove`, etc.
  - Advanced functions: `wtgo`, `wtcd`, `wtfork`, `wtsync`
  - Tab completion for branch names (bash/zsh)
  - Flexible script location detection

- **Comprehensive testing**
  - 60+ tests covering core functionality, edge cases, and error handling
  - Bats testing framework integration
  - Automated test runner with detailed reporting
  - Mock utilities for testing error conditions

- **Location independence**
  - Works from any directory within git repository
  - Script can be placed anywhere (project, system, user bin)
  - Multiple fallback strategies for git root detection
  - No assumptions about script location

- **Error handling and validation**
  - Graceful handling of file system errors
  - Input validation and sanitization
  - Clear error messages and suggestions
  - Recovery from common failure scenarios

- **Documentation**
  - Comprehensive README with usage examples
  - Installation guide for various deployment scenarios
  - Testing guide for contributors and users
  - Inline code documentation

### Default Configuration
- `.env`, `.env.local`, `.env.development`, `.env.test`
- `.vscode/settings.json`, `.vscode/launch.json`
- `config/local.json`, `config/development.json`
- `.taskmaster/config.json`
- `.mcp.json`

### Supported Platforms
- macOS (bash 3.2+)
- Linux (bash 4.0+)
- Windows (Git Bash, WSL)

### Dependencies
- Git 2.5+ with worktree support
- Bash 4.0+ (or compatible shell)
- Standard Unix tools (awk, sed, grep, find)

## Future Enhancements

### Planned Features
- Remote repository cloning for worktrees
- Integration with git hooks
- Worktree templates
- Bulk operations on multiple worktrees
- Integration with popular development tools
- Performance optimizations for large repositories
- GUI wrapper for non-command-line users

### Under Consideration
- Support for git submodules in worktrees
- Automatic dependency detection for config files
- Integration with CI/CD systems
- Docker container support
- IDE plugins (VSCode, IntelliJ)
- Git LFS compatibility improvements