# Git Worktree Manager - Installation Guide

Complete git worktree management solution with automatic config file copying, comprehensive testing, and convenient shell shortcuts.

## Recommended Installation (~/.local/bin)

### Quick Setup - Both Scripts
```bash
# Create user bin directory
mkdir -p ~/.local/bin

# Download and install both scripts
curl -o ~/.local/bin/git-worktree-manager https://raw.githubusercontent.com/joel-eq/worktree-manager/main/git-worktree-manager.sh
curl -o ~/.local/bin/worktree-shortcuts.sh https://raw.githubusercontent.com/joel-eq/worktree-manager/main/worktree-shortcuts.sh

# Make executable
chmod +x ~/.local/bin/git-worktree-manager

# Add to PATH (if not already there)
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
fi

# Add shortcuts to shell
echo 'source ~/.local/bin/worktree-shortcuts.sh' >> ~/.zshrc

# Reload shell configuration
source ~/.zshrc
```

### Verification
```bash
# Test main script
git-worktree-manager help

# Test shortcuts (in any git repo)
cd your-git-project
wtcreate feature/test-branch
wtlist
wtremove feature/test-branch --force
```

### Usage Examples
```bash
# Using the main script
git-worktree-manager create feature/auth-system
git-worktree-manager list
git-worktree-manager config --list

# Using convenient shortcuts
wtcreate feature/ui-redesign    # Create worktree
wtgo feature/auth-system        # Switch to existing worktree
wtlist                          # List all worktrees
wtfork hotfix                   # Fork current branch
wtsync                          # Sync all worktrees
wthelp                          # Show shortcuts help
```

## Alternative Installation Methods

### Option 1: Local Project Installation
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
sudo cp worktree-manager/worktree-shortcuts.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/git-worktree-manager

# Add shortcuts globally
echo 'source /usr/local/bin/worktree-shortcuts.sh' | sudo tee -a /etc/bash.bashrc

# Use from any git project
cd any-git-project
git-worktree-manager create feature/ui
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

### Remove ~/.local/bin installation
```bash
# Remove both scripts
rm -f ~/.local/bin/git-worktree-manager
rm -f ~/.local/bin/worktree-shortcuts.sh

# Remove shortcuts from shell config (edit ~/.bashrc and remove these lines):
# export PATH="$HOME/.local/bin:$PATH"
# source ~/.local/bin/worktree-shortcuts.sh
```

### Remove other installations
```bash
# Remove global installation
sudo rm -f /usr/local/bin/git-worktree-manager
sudo rm -f /usr/local/bin/worktree-shortcuts.sh

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