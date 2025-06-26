# Git Worktree Manager - Installation Guide

Complete git worktree management solution with automatic config file copying, comprehensive testing, and convenient shell shortcuts.

## Quick Install

### Option 1: Local Project Installation (Recommended)
```bash
# Clone or copy the worktree-manager directory to your project
cd your-project
cp -r /path/to/worktree-manager .

# Use directly
./worktree-manager/git-worktree-manager.sh create feature/auth

# Or add shortcuts to your shell
echo 'source $(pwd)/worktree-manager/worktree-shortcuts.sh' >> ~/.bashrc
source ~/.bashrc
wtcreate feature/auth
```

### Option 2: Global System Installation
```bash
# Install to system bin directory
sudo cp worktree-manager/git-worktree-manager.sh /usr/local/bin/git-worktree-manager
sudo chmod +x /usr/local/bin/git-worktree-manager

# Use from any git project
cd any-git-project
git-worktree-manager create feature/ui
```

### Option 3: User Local Installation
```bash
# Install to user bin directory
mkdir -p ~/.local/bin
cp worktree-manager/git-worktree-manager.sh ~/.local/bin/git-worktree-manager
chmod +x ~/.local/bin/git-worktree-manager

# Add to PATH (if not already)
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Add shortcuts
echo 'source /path/to/worktree-manager/worktree-shortcuts.sh' >> ~/.bashrc
```

## Requirements

- **Git 2.5+** with worktree support
- **Bash 4.0+** (or compatible shell)
- **Standard Unix tools**: `awk`, `sed`, `grep`, `find`

### Optional Dependencies
- **Bats** for running tests: `brew install bats-core` or `npm install -g bats`
- **Git completion** for enhanced tab completion

## Verification

Test your installation:

```bash
# Test basic functionality
git-worktree-manager help

# Test in a git repository
cd some-git-repo
git-worktree-manager list

# Test shortcuts (if installed)
wthelp
```

## Uninstall

```bash
# Remove global installation
sudo rm -f /usr/local/bin/git-worktree-manager

# Remove user installation
rm -f ~/.local/bin/git-worktree-manager

# Remove shortcuts from shell config
# Edit ~/.bashrc and remove the source line

# Remove project installation
rm -rf ./worktree-manager
```

## Troubleshooting

### Permission Denied
```bash
chmod +x git-worktree-manager.sh
```

### Command Not Found
- Check PATH includes installation directory
- Verify script is executable
- Use absolute path as fallback

### Git Errors
- Ensure you're in a git repository
- Check git version: `git --version`
- Verify repository is not corrupted

For more help, see [README.md](README.md) or run tests with `./run_tests.sh`.