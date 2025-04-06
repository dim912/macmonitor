# Mac System Monitor - User Guide

Welcome to the Mac System Monitor! This guide will help you get the most out of your monitoring system after installation.

## 🚀 Quick Start After Installation

Once you've installed Mac System Monitor, your system is already being monitored in the background. Here's how to see your stats right away:

```bash
# For manual installation - watch stats in real-time
tail -f ~/monitor_logs/dual_monitor_log_$(date +%Y-%m-%d).txt

# For Homebrew installation - use the show command for formatted output
mm show        # Shows default 20 entries
mm show -l 100 # Shows 100 most recent entries
```

This command will show you a live feed of your system metrics as they're being recorded!

## 📊 Understanding Your Stats

The monitor displays several key metrics in a table format:

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

## 🔔 Alerts Explained

Mac System Monitor will show alerts in the rightmost column when it detects abnormal conditions:

- `[CPU 92/85°C +8%]`: CPU temperature exceeds threshold (default: 85°C)
- `[GPU 91/85°C +7%]`: GPU temperature exceeds threshold (default: 85°C)
- `[WS CPU 52/50% +4%]`: WindowServer CPU usage exceeds threshold (default: 50%)
- `[SWAP 600/500MB +20%]`: Swap usage exceeds threshold (default: 500MB)
- `[FAN 5200/5000 +4%]`: Fan speed exceeds threshold (default: 5000 RPM)
- `[MEM 92/90% +2%]`: Memory pressure exceeds threshold (default: 90%) for consecutive readings

The new alert format shows: `[TYPE current/threshold +percentage]` for easier interpretation.

### Alert Management System

To prevent alert fatigue, Mac System Monitor includes intelligent alert management:

1. **Severity Levels**: Alerts are categorized as Low (🟡), Medium (🟠), or High (🔴) based on how far they exceed thresholds
2. **Alert Cooldown**: Once an alert for a specific metric is shown, it won't trigger again for the set cooldown period (default: 10 minutes)
3. **Do Not Disturb**: You can schedule quiet hours when no alerts will appear (great for nighttime)
4. **Alert Aggregation**: Multiple alerts are combined into a single notification
5. **Smart Thresholds**: Over time, the system can learn what's normal for your Mac (optional)

When alerts are triggered, you'll receive macOS notifications with appropriate color indicators. For memory alerts, details about top memory-consuming applications are logged to:
```bash
~/monitor_logs/alerts/memory_alerts_$(date +%Y-%m-%d).log
```

### Customizing Alert Behavior

You can easily customize alert settings with the `mm config` command:

```bash
# View all current settings
mm config list

# Alert management examples
mm config set beeps 1             # Number of beeps per alert (0-10)
mm config set cooldown 5          # Minutes between alerts of same type (1-60)
mm config set severity 1          # Minimum severity level (1=low, 2=medium, 3=high)
mm config set dnd on              # Enable Do Not Disturb mode
mm config set dnd-start 22:00     # Set DND start time (24-hour format)
mm config set dnd-end 07:00       # Set DND end time
mm config set smart on            # Enable smart adaptive thresholds
```

## 💻 Daily Usage

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

## 🔧 Customization

You can customize the monitor's behavior by editing the script:

```bash
# Edit the monitor settings
nano ~/.monitor/monitor_status.sh
```

Common settings to customize:
- `INTERVAL=30` - Change monitoring frequency (in seconds)
- Alert thresholds (search for lines with `gt` and numbers)
- Log cleanup duration - the `find "$LOG_DIR"` lines determine how long logs are kept

After making changes, restart the service:
```bash
./restart_monitor.sh
```

## 📱 Tips & Tricks

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

## 🛟 Troubleshooting

- **Missing Values**: Some metrics may show N/A depending on your Mac model
- **Temperature Reading Issues**: Run `./test_monitor.sh` to check what's available
- **Script Not Running**: Check service status with `launchctl list | grep monitorlogger`

See the main [README.md](README.md) for more detailed troubleshooting options.

---

Enjoy your Mac System Monitor! Happy monitoring! 🖥️
