# Git Worktree Manager

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Bash](https://img.shields.io/badge/bash-%3E%3D4.0-green.svg)
![Git](https://img.shields.io/badge/git-%3E%3D2.5-orange.svg)
![Tests](https://img.shields.io/badge/tests-60%2B-brightgreen.svg)

A comprehensive command-line tool for managing git worktrees with automatic configuration file copying, shell integration, and robust testing.

## ✨ Features

🚀 **Complete Worktree Management**
- Create, list, remove, and switch between worktrees
- Smart branch handling (local, remote, new branches)
- Automatic cleanup of orphaned worktrees

⚙️ **Automatic Config Copying**
- Copy `.env`, `.mcp.json`, `.vscode/` settings, and more to new worktrees
- Configurable file list with persistent settings
- Maintains consistent development environments

🌍 **Location Independent** 
- Works from any directory within a git repository
- Multiple installation options (project-local, user, system-wide)
- Intelligent git root detection

🔧 **Shell Integration**
- Convenient aliases (`wt`, `wtcreate`, `wtlist`, etc.)
- Advanced functions (`wtgo`, `wtcd`, `wtfork`, `wtsync`)
- Tab completion for branch names

🧪 **Thoroughly Tested**
- 60+ automated tests covering core functionality and edge cases
- Bats testing framework with comprehensive test suite
- CI/CD ready with detailed test reporting

## 🚀 Quick Start

### Installation

**Option 1: Download and use locally**
```bash
# Download to your project
curl -L https://github.com/joel-eq/worktree-manager/archive/main.tar.gz | tar xz
cd worktree-manager-main

# Use directly
./git-worktree-manager.sh create feature/auth-system
```

**Option 2: Global installation**
```bash
# Download and install globally
curl -o git-worktree-manager.sh https://raw.githubusercontent.com/joel-eq/worktree-manager/main/git-worktree-manager.sh
chmod +x git-worktree-manager.sh
sudo mv git-worktree-manager.sh /usr/local/bin/git-worktree-manager

# Use from any git repository
cd any-git-project
git-worktree-manager create feature/ui-redesign
```

**Option 3: With shell shortcuts**
```bash
# Add to your shell profile
curl -o worktree-shortcuts.sh https://raw.githubusercontent.com/joel-eq/worktree-manager/main/worktree-shortcuts.sh
echo 'source /path/to/worktree-shortcuts.sh' >> ~/.bashrc
source ~/.bashrc

# Use convenient aliases
wtcreate feature/api-refactor
wtlist
wtgo main
```

### Basic Usage

```bash
# Create worktree for a new feature
git-worktree-manager create feature/user-authentication

# List all worktrees
git-worktree-manager list

# Remove worktree when done
git-worktree-manager remove feature/user-authentication

# Show help
git-worktree-manager help
```

## 📖 Documentation

### Core Commands

| Command | Description | Example |
|---------|-------------|---------|
| `create <branch> [path]` | Create new worktree | `create feature/auth` |
| `list` | List all worktrees | `list` |
| `remove <branch\|path>` | Remove worktree | `remove feature/auth` |
| `cleanup` | Clean orphaned worktrees | `cleanup` |
| `switch <branch>` | Switch to worktree | `switch main` |
| `status` | Show worktree status | `status` |
| `config` | Manage config files | `config --list` |

### Configuration Management

```bash
# View current config files
git-worktree-manager config --list

# Add file to copy list
git-worktree-manager config --add .env.production

# Remove file from copy list  
git-worktree-manager config --remove .vscode/settings.json

# Reset to defaults
git-worktree-manager config --reset
```

### Shell Shortcuts

```bash
# Basic aliases
wt list                    # Same as git-worktree-manager list
wtcreate feature/auth      # Create worktree
wtremove feature/auth      # Remove worktree

# Advanced functions
wtgo feature/auth          # Create if needed, then switch to it
wtcd main                  # Change directory to main worktree
wtfork v2                  # Create fork of current branch
wtsync                     # Pull latest in all worktrees
```

### Default Config Files

The following files are automatically copied to new worktrees:

- **Environment**: `.env`, `.env.local`, `.env.development`, `.env.test`
- **Editor**: `.vscode/settings.json`, `.vscode/launch.json`
- **Project Config**: `config/local.json`, `config/development.json`
- **Tools**: `.taskmaster/config.json`, `.mcp.json`

## 🎯 Use Cases

### Multi-Feature Development
Work on multiple features simultaneously without branch switching:

```bash
wtcreate feature/auth-system
wtcreate feature/ui-redesign  
wtcreate hotfix/critical-bug

# Each in separate terminal/IDE instance
wtcd feature/auth-system    # Terminal 1
wtcd feature/ui-redesign    # Terminal 2  
wtcd hotfix/critical-bug    # Terminal 3
```

### Experimentation
Try different approaches safely:

```bash
wtfork approach-a          # Create experimental branch
wtfork approach-b          # Create alternative approach
# Compare implementations, keep the best one
```

### Code Review Workflow
Review PRs without losing current work:

```bash
wtcreate pr/123-review     # Create worktree for PR review
# Review code, test changes
wtremove pr/123-review     # Clean up when done
```

### Release Management
Maintain multiple release branches:

```bash
wtcreate release/v2.1      # Prepare release
wtcreate hotfix/v2.0.1     # Emergency fix for current release
# Work on both simultaneously
```

## 🔧 Advanced Configuration

### Custom Config Files
Create `.worktree-config` in your project root:

```
# Custom files to copy
.env.custom
docker-compose.override.yml
config/app-local.json
```

### Command-Line Overrides
```bash
# Copy only specific files
git-worktree-manager create feature/db --config-files ".env,.env.local"

# Skip config copying entirely
git-worktree-manager create feature/minimal --no-copy-configs

# Use custom base directory
git-worktree-manager create feature/test -d /tmp/worktrees
```

## 🧪 Testing

Run the comprehensive test suite:

```bash
# Install Bats testing framework
brew install bats-core              # macOS
sudo apt-get install bats           # Ubuntu
npm install -g bats                 # npm

# Run all tests
./run_tests.sh

# Run specific tests
./run_tests.sh --test test_core_functionality.bats

# Verbose output
./run_tests.sh --verbose
```

Test coverage includes:
- ✅ Core functionality (create, list, remove)
- ✅ Configuration management
- ✅ Edge cases and error handling  
- ✅ Shell shortcuts integration
- ✅ File system operations
- ✅ Git integration scenarios

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Quick Development Setup
```bash
git clone https://github.com/joel-eq/worktree-manager/git-worktree-manager.git
cd git-worktree-manager

# Run tests to verify setup
./run_tests.sh

# Make changes and test
./git-worktree-manager.sh help
```

### Reporting Issues
- 🐛 [Bug Reports](https://github.com/joel-eq/worktree-manager/issues/new?template=bug_report.md)
- 💡 [Feature Requests](https://github.com/joel-eq/worktree-manager/issues/new?template=feature_request.md)
- 📖 [Documentation Issues](https://github.com/joel-eq/worktree-manager/issues/new?template=documentation.md)

## 📋 Requirements

- **Git 2.5+** with worktree support
- **Bash 4.0+** (or compatible shell)
- **Standard Unix tools**: `awk`, `sed`, `grep`, `find`

### Platform Support
- ✅ **macOS** (bash 3.2+)
- ✅ **Linux** (bash 4.0+)  
- ✅ **Windows** (Git Bash, WSL)

## 📚 Additional Documentation

- 📦 [Installation Guide](INSTALL.md) - Detailed installation options
- 🧪 [Testing Guide](TESTING.md) - Running and writing tests  
- 📝 [Changelog](CHANGELOG.md) - Version history and updates

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
