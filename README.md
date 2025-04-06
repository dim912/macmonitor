# Mac System Monitor 🖥️

A lightweight macOS system monitoring tool that logs system metrics and provides alerts for abnormal conditions. This tool works for any macOS user and is designed to be easily shared and deployed.

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS-blue" alt="Platform macOS">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="MIT License">
  <img src="https://img.shields.io/badge/Version-1.0.0-orange" alt="Version 1.0.0">
</p>

## Table of Contents
- [Features](#features)
- [Quick Start](#quick-start-)
- [Understanding Your Stats](#understanding-your-stats-)
- [Alerts Explained](#alerts-explained-)
- [Daily Usage](#daily-usage-)
- [Requirements](#requirements)
- [Management Commands](#management-commands-)
- [Permissions](#permissions)
- [Common Questions](#common-questions-)
- [Troubleshooting](#troubleshooting-)
- [Contributing](#contributing-)
- [License](#license-)

## Features

- **Real-time Monitoring** of:
  - CPU temperature
  - GPU temperature
  - WindowServer CPU usage
  - Memory pressure
  - Swap usage
  - Fan speed
  - System uptime

- **Alerting System** for:
  - High CPU/GPU temperatures
  - Excessive WindowServer CPU usage
  - High swap usage
  - High fan speeds
  - Low memory conditions

- **Logging System** that:
  - Creates daily logs of system metrics
  - Maintains separate alert logs
  - Auto-deletes logs older than 2 days

## Quick Start ⚡

### Installation via Homebrew (Recommended)

```bash
# Add the tap
brew tap username/macmonitor

# Install Mac System Monitor
brew install macmonitor
```

After installing via Homebrew, you can use the following simple commands:

```bash
mm show               # Show stats in CLI with auto-update
mm config             # Configure alert thresholds
mm test               # Test available metrics
mm restart            # Start/restart monitoring service
mm uninstall          # Remove the monitoring service
mm help               # Display detailed help information
```

### One-Line Installation (Alternative)

```bash
# Install with one command:
bash -c "$(curl -fsSL https://raw.githubusercontent.com/user/mac-system-monitor/main/install_curl.sh)"
```

### Manual Installation

```bash
# Download and extract the project, then:
chmod +x install_monitor.sh
./install_monitor.sh
```

### After Installation

Your Mac is already being monitored! View your stats with:

```bash
# Watch your system in real-time
tail -f ~/monitor_logs/dual_monitor_log_$(date +%Y-%m-%d).txt

# See just the last 20 readings
tail -n 20 ~/monitor_logs/dual_monitor_log_$(date +%Y-%m-%d).txt

# View today's complete log file
cat ~/monitor_logs/dual_monitor_log_$(date +%Y-%m-%d).txt

# Show stats in CLI with auto-update
# For Homebrew installation:
mm show        # Shows default 20 entries
mm show -l 100 # Shows 100 most recent entries
```

The installer automatically:
1. Creates a `.monitor` directory in your home folder
2. Installs required dependencies (Homebrew, osx-cpu-temp, iStats)
3. Creates a user-specific LaunchAgent to run the monitor at startup
4. Sets up GPU temperature monitoring (if you choose to)

## Understanding Your Stats 📊

Mac System Monitor tracks critical system metrics in a table format:

| Column | Description | Normal Range | What to Watch For |
|--------|-------------|--------------|-------------------|
| Time | Timestamp of the reading | - | - |
| CPU°C | CPU temperature | 30-80°C | >85°C indicates high load |
| GPU°C | GPU temperature | 30-80°C | >85°C indicates GPU stress |
| WS CPU% | WindowServer process CPU usage | 1-20% | >50% can indicate GPU/UI issues |
| Mem Status | Memory pressure indicator | Normal/70-85% | "Warning" or "Critical" needs attention |
| Swap Used | Amount of swap memory in use | 0-100M | >500M indicates memory pressure |
| Fan RPM | Fan speed in rotations per minute | 1000-3000 RPM | >5000 RPM indicates cooling stress |
| Uptime | How long your system has been running | - | - |
| Alerts | Any active alerts detected | Empty is good | Any text here indicates an issue |

Example output:
```
| 2025-04-06 14:32:45 | 65°C  | 72°C  | 3.2%   | Normal     | 0.00M    | 2341   | 5:00           |                |
| 2025-04-06 14:33:15 | 78°C  | 89°C  | 25.7%  | Normal     | 0.00M    | 3100   | 5:01           | [GPU 89/85°C +4%] |
| 2025-04-06 14:33:45 | 92°C  | 91°C  | 52.3%  | 92%        | 600M     | 5200   | 5:01           | [CPU 92/85°C +8%] [GPU 91/85°C +7%] [WS CPU 52/50% +4%] [SWAP 600/500MB +20%] [FAN 5200/5000 +4%] |
```

The alert column now shows both the current value and threshold, with percentage over threshold for more insightful monitoring.

All data is logged to `~/monitor_logs/` with separate alert logs for detailed troubleshooting.

## Alerts Explained 🔔

Mac System Monitor will show alerts in the rightmost column when it detects abnormal conditions:

- `[CPU 92/85°C +8%]`: CPU temperature exceeds threshold (default: 85°C)
- `[GPU 91/85°C +7%]`: GPU temperature exceeds threshold (default: 85°C)
- `[WS CPU 52/50% +4%]`: WindowServer CPU usage exceeds threshold (default: 50%)
- `[SWAP 600/500MB +20%]`: Swap usage exceeds threshold (default: 500MB)
- `[FAN 5200/5000 +4%]`: Fan speed exceeds threshold (default: 5000 RPM)
- `[MEM 92/90% +2%]`: Memory pressure exceeds threshold (default: 90%) for consecutive readings

The new alert format shows: `[TYPE current/threshold +percentage]` for easier interpretation.

### Alert Management Features

Mac System Monitor includes advanced alert management to minimize disruptions:

- **Alert Severity Levels**: Low, Medium, and High severity with color-coded notifications
- **Alert Cooldown**: Prevents repeat notifications of the same issue (default: 10 minutes)
- **Do Not Disturb Mode**: Automatically silence alerts during specific hours
- **Alert Aggregation**: Multiple issues are grouped into a single notification
- **Smart Thresholds**: Optional adaptive thresholds based on your system's normal behavior

### Customizing Alerts

You can customize both thresholds and alert behavior:

```bash
# Threshold settings
mm config list                    # Show current thresholds and alert settings
mm config set cpu 80              # Change CPU temperature threshold to 80°C
mm config set gpu 80              # Change GPU temperature threshold
mm config set wscpu 40            # Change WindowServer CPU usage threshold to 40%
mm config set swap 1000           # Change swap usage threshold to 1000MB
mm config set fan 6000            # Change fan speed threshold to 6000 RPM
mm config set memory 85           # Change memory pressure threshold to 85%
mm config set streak 2            # Alert after 2 consecutive readings (default: 3)

# Alert management settings
mm config set beeps 1             # Number of beeps per alert (default: 2)
mm config set cooldown 5          # Minutes between alerts of same type (default: 10)
mm config set severity 3          # Minimum severity level (1=low, 2=medium, 3=high)
mm config set dnd on              # Enable Do Not Disturb mode (on/off)
mm config set dnd-start 22:00     # Set DND start time (24-hour format)
mm config set dnd-end 07:00       # Set DND end time
mm config set smart on            # Enable smart thresholds (on/off)
mm config reset                   # Reset all settings to defaults
```

When alerts are triggered, you'll also receive macOS notifications. For memory alerts, details about top memory-consuming applications are logged to:
```bash
~/monitor_logs/alerts/memory_alerts_$(date +%Y-%m-%d).log
```

## Daily Usage 💻

### Checking Current System Status

```bash
# View today's log file
cat ~/monitor_logs/dual_monitor_log_$(date +%Y-%m-%d).txt

# Watch stats in real-time (press Ctrl+C to exit)
tail -f ~/monitor_logs/dual_monitor_log_$(date +%Y-%m-%d).txt

# See just the last 20 readings
tail -n 20 ~/monitor_logs/dual_monitor_log_$(date +%Y-%m-%d).txt
```

### Checking for Alert History

```bash
# View memory alerts from today
cat ~/monitor_logs/alerts/memory_alerts_$(date +%Y-%m-%d).log

# Check if any alerts happened in the last hour
grep "$(date +%Y-%m-%d\ %H)" ~/monitor_logs/dual_monitor_log_$(date +%Y-%m-%d).txt | grep "\["
```

### Tips & Tricks

<details>
<summary>Click to expand tips & tricks</summary>

1. **Create a Terminal Alias**

   Add this to your `~/.bashrc` or `~/.zshrc`:
   ```bash
   alias monitor-stats='tail -f ~/monitor_logs/dual_monitor_log_$(date +%Y-%m-%d).txt'
   ```
   Then simply type `monitor-stats` anytime to watch your system metrics!

2. **Split-Screen Monitoring**

   When gaming or running intensive applications, keep a terminal window open with:
   ```bash
   tail -f ~/monitor_logs/dual_monitor_log_$(date +%Y-%m-%d).txt | grep -v "N/A"
   ```
   This will filter out any N/A values and show you only the available metrics.

3. **Track System Performance Over Time**

   To see how your system performed during a specific time period:
   ```bash
   grep "14:00" ~/monitor_logs/dual_monitor_log_$(date +%Y-%m-%d).txt
   ```
   This would show all readings from 2:00 PM.
</details>

## Requirements

- macOS 10.13 or later
- Admin privileges (for installing dependencies - one time only)

## Management Commands 🛠️

```bash
# Test what metrics are available on your system
./test_monitor.sh

# Update the monitoring script without reinstalling
./restart_monitor.sh

# Uninstall the monitoring system
./uninstall_monitor.sh
```

## Permissions

Some metrics require special permissions:
- **GPU Temperature**: The script tries multiple methods to get this data:
  - Powermetrics (primary method, requires sudo privileges)
  - System Profiler as fallback (less accurate but more compatible)
  
  GPU temperature monitoring is configured during installation. You'll be asked if you want to set up passwordless sudo access for the powermetrics command.
  
- **CPU Temperature**: The script tries:
  - osx-cpu-temp tool (primary method)
  - System Profiler as fallback
  
- **Fan Speed**: The script tries:
  - iStats gem (primary method)
  - SMC Fan Control as fallback (if installed)

The script is designed to be resilient - if a metric isn't available with one method, it will try alternatives or gracefully show N/A.

## Common Questions ❓

<details>
<summary>Why do some metrics show "N/A"?</summary>

Different Mac models expose different metrics:
- **CPU/GPU Temperature**: Some Mac models restrict access to this data
- **Fan Speed**: Not all Mac models expose fan information

Run `./test_monitor.sh` to see what's available on your Mac.
</details>

<details>
<summary>How do I get GPU temperature working?</summary>

During installation, answer "y" when asked to set up GPU monitoring. If you skipped it:
1. Run the installer again: `./install_monitor.sh`
2. Answer "y" to the GPU setup question
</details>

<details>
<summary>How do I change the monitoring interval?</summary>

Edit `~/.monitor/monitor_status.sh` and change the `INTERVAL=30` value, then run `./restart_monitor.sh`.
</details>

## Troubleshooting 🔍

If you're having issues:

1. **Check if the service is running**:
   ```bash
   launchctl list | grep monitorlogger
   ```

2. **View error logs**:
   ```bash
   cat /tmp/monitorlogger.err
   ```

3. **Restart the service**:
   ```bash
   ./restart_monitor.sh
   ```

For more detailed troubleshooting and advanced usage options, see the [📚 Advanced Usage Guide](ADVANCED_USAGE.md).

## Contributing 🤝

We welcome contributions from the community! Please see the [Contributing Guide](CONTRIBUTING.md) for details on how to get started.

This project adheres to our [Code of Conduct](CODE_OF_CONDUCT.md).

## License 📄

Mac System Monitor is released under the [MIT License](LICENSE).
