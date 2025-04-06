# Using the Local `mm` Command Script

The `mm` command script provides a unified, Linux-style interface for Mac System Monitor without requiring Homebrew installation. This simplified approach gives you immediate access to all functionality.

## Getting Started

The script is already in your project directory and is ready to use:

```bash
# Make sure it's executable (already done)
chmod +x mm

# View available commands
./mm
```

## Available Commands

```bash
# Show system stats in CLI with auto-update (live view)
./mm cli

# Open the dashboard in your browser
./mm view

# Generate a new dashboard with the latest data
./mm update

# Test what metrics are available on your system
./mm test

# Start/restart the monitoring service
./mm restart

# Uninstall the monitoring service
./mm uninstall
```

## Adding to Your PATH (Optional)

If you want to use the `mm` command from anywhere, you can add it to your PATH:

1. Create a bin directory in your home folder (if it doesn't exist):
   ```bash
   mkdir -p ~/bin
   ```

2. Copy or symlink the mm script:
   ```bash
   # Option 1: Copy the script
   cp mm ~/bin/
   
   # Option 2: Create a symlink (better if you'll edit the script)
   ln -s "$(pwd)/mm" ~/bin/mm
   ```

3. Add the bin directory to your PATH by adding this line to your `~/.zshrc` or `~/.bashrc`:
   ```bash
   export PATH="$HOME/bin:$PATH"
   ```

4. Reload your shell configuration:
   ```bash
   source ~/.zshrc  # or source ~/.bashrc
   ```

5. Now you can use `mm` from anywhere:
   ```bash
   mm cli
   mm view
   ```

## Creating Aliases (Optional)

For even faster access, you can create aliases in your shell configuration:

```bash
# Add to ~/.zshrc or ~/.bashrc
alias mm-stats='mm cli'
alias mm-dash='mm view'
```

## Using with Keyboard Shortcuts

See the [Keyboard Shortcut Setup Guide](create_keyboard_shortcut.md) to create macOS shortcuts for quick access to the dashboard.

---

This local command approach provides all the functionality that would be available through Homebrew, but with simpler installation and maintenance.
