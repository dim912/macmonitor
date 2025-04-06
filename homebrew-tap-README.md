# MacMonitor Homebrew Tap

This repository contains Homebrew formulae for installing MacMonitor and related tools.

## What is MacMonitor?

MacMonitor is a lightweight system monitoring tool for macOS that provides real-time metrics on CPU usage, temperatures, GPU usage, memory usage, swap usage, fan speeds, and system uptime. It supports customizable alerts and can be configured for continuous monitoring.

## Installation

### Installing MacMonitor

```bash
# Add this tap
brew tap dim912/tap

# Install MacMonitor
brew install macmonitor
```

Or, in a single command:

```bash
brew install dim912/tap/macmonitor
```

### Updating

When a new version is available, simply run:

```bash
brew update
brew upgrade macmonitor
```

## Available Formulae

- **macmonitor**: The main system monitoring tool

## Usage

After installation, you can run MacMonitor using:

```bash
macmonitor
```

For more options, run:

```bash
macmonitor --help
```

## Configuration

MacMonitor's configuration files are installed in the Homebrew prefix directory. You can customize alert thresholds by modifying:

```
$(brew --prefix)/opt/macmonitor/config_thresholds.sh
```

## Automatic Startup

To configure MacMonitor to run at system startup:

1. Copy the LaunchDaemon template:
   ```bash
   sudo cp $(brew --prefix)/opt/macmonitor/templates/com.user.monitorlogger.plist.template /Library/LaunchDaemons/com.user.macmonitor.plist
   ```

2. Edit the file to set the correct paths:
   ```bash
   sudo nano /Library/LaunchDaemons/com.user.macmonitor.plist
   ```

3. Load the LaunchDaemon:
   ```bash
   sudo launchctl load /Library/LaunchDaemons/com.user.macmonitor.plist
   ```

## Website Deployment

MacMonitor includes scripts for deploying its documentation website to Amazon S3:

```bash
cd $(brew --prefix)/opt/macmonitor/deploy
./deploy-final.sh
```

See the `s3-public-access-guide.md` file for instructions on configuring bucket permissions.

## Issues and Contributing

If you encounter any problems with these Homebrew formulae, please file an issue on GitHub at [https://github.com/dim912/macmonitor/issues](https://github.com/dim912/macmonitor/issues).

Contributions via pull requests are welcome!

## License

MacMonitor is released under the MIT License.
