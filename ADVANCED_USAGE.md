# Mac System Monitor - Advanced Usage Guide

This guide provides detailed information about advanced features, customization options, and troubleshooting for the Mac System Monitor. For basic setup and usage, refer to the [README.md](README.md).

## 🔧 Customizing Your Monitor

### Changing Monitoring Intervals

You can adjust how frequently the system collects metrics:

```bash
# Edit the monitor settings file
nano ~/.monitor/monitor_status.sh

# Find and change the INTERVAL value (in seconds)
# Default is 30 seconds
INTERVAL=30

# Save the file and restart the service
./restart_monitor.sh
```

### Modifying Alert Thresholds

The monitor uses default thresholds for alerts, but you can customize them:

```bash
# Edit the monitor script
nano ~/.monitor/monitor_status.sh

# Find and adjust alert thresholds
# Examples:
# CPU_TEMP_THRESHOLD=85  # Default CPU temperature threshold (°C)
# GPU_TEMP_THRESHOLD=85  # Default GPU temperature threshold (°C)
# WS_CPU_THRESHOLD=50    # Default WindowServer CPU usage threshold (%)
# SWAP_THRESHOLD=500     # Default swap usage threshold (MB)
# FAN_THRESHOLD=5000     # Default fan speed threshold (RPM)
```

### Customizing Log Retention

By default, logs older than 2 days are automatically deleted. To change this:

```bash
# Edit the monitor script
nano ~/.monitor/monitor_status.sh

# Find the log cleanup section (search for "find")
# Change the -mtime value to adjust retention period
find "$LOG_DIR" -name "*.txt" -mtime +2 -delete
```

## 🔍 Advanced Troubleshooting

### Debugging Installation Issues

If the installation process encounters problems:

1. **Check installation logs**:
   ```bash
   cat ~/.monitor/install.log
   ```

2. **Verify dependencies**:
   ```bash
   # Check if Homebrew is installed
   which brew
   
   # Verify osx-cpu-temp installation
   which osx-cpu-temp
   
   # Verify iStats installation
   gem list iStats
   ```

3. **Check LaunchAgent permissions**:
   ```bash
   ls -la ~/Library/LaunchAgents/com.$(whoami).monitorlogger.plist
   # Should show: -rw-r--r--
   ```

### Service Not Starting

If the monitoring service doesn't start:

1. **Verify LaunchAgent loading**:
   ```bash
   launchctl list | grep monitorlogger
   ```

2. **Check system log for launchd errors**:
   ```bash
   log show --predicate 'subsystem == "com.apple.launchd"' --last 1h | grep monitor
   ```

3. **Try manual service start**:
   ```bash
   launchctl load -w ~/Library/LaunchAgents/com.$(whoami).monitorlogger.plist
   ```

4. **Try running the monitor script directly**:
   ```bash
   ~/.monitor/monitor_status.sh
   ```

### Missing or Incomplete Metrics

If certain metrics show as "N/A" or seem incorrect:

1. **Run the test script with verbose output**:
   ```bash
   ./test_monitor.sh -v
   ```

2. **Check permission issues for GPU temp**:
   ```bash
   # Test sudo access for powermetrics
   sudo -n powermetrics --samplers smc -n1 2>/dev/null | grep -i "GPU die temperature"
   ```

3. **Test individual metric collection tools**:
   ```bash
   # Test CPU temperature
   osx-cpu-temp
   
   # Test iStats
   istats
   ```

## 🛠️ Advanced Features and Techniques

### Custom Metrics Integration

You can modify the monitor script to add custom metrics:

1. Edit the monitor script:
   ```bash
   nano ~/.monitor/monitor_status.sh
   ```

2. Add a new function to collect your custom metric
3. Update the log output format to include your new metric
4. Restart the service with `./restart_monitor.sh`

### Analyzing Historical Data

For long-term performance analysis:

```bash
# Collect all temperature readings above 80°C from the past week
find ~/monitor_logs -name "dual_monitor_log_*.txt" -mtime -7 | xargs grep -E "8[0-9]°C|9[0-9]°C"

# Find patterns in swap usage
find ~/monitor_logs -name "dual_monitor_log_*.txt" -mtime -7 | xargs grep -E "\|\s+[5-9][0-9][0-9]\.[0-9]+M"

# Count total alerts by type
grep -r "\[" ~/monitor_logs | sort | uniq -c | sort -rn
```

### Setting Up Email Alerts

You can modify the monitor script to send email alerts for critical conditions:

1. Install the `mail` command if not already available:
   ```bash
   brew install mailutils
   ```

2. Add an email notification function to the monitor script:
   ```bash
   send_email_alert() {
     local subject="$1"
     local message="$2"
     echo "$message" | mail -s "$subject" your-email@example.com
   }
   ```

3. Call this function when alerts are triggered

## 📱 Advanced User Tips

### Creating a Status Bar Menu Item

For macOS users who want system stats in their menu bar:

1. Consider installing [BitBar](https://github.com/matryer/bitbar) or [xbar](https://xbarapp.com/)
2. Create a BitBar/xbar plugin that reads from your monitor logs
3. See your system stats directly from the menu bar

### Integration with Other Tools

Mac System Monitor works well with other monitoring and automation tools:

1. **Using with Grafana/InfluxDB**:
   - You can parse the log files and send metrics to InfluxDB
   - Then create Grafana dashboards for visualization

2. **Apple Shortcuts Integration**:
   - Create shortcuts to display recent alerts or stats
   - Trigger actions based on monitoring results

3. **Automator Workflows**:
   - Create workflows that process logs and perform actions
   - Use Calendar to schedule regular report generation

### Terminal Multiplexer Setup

For power users who want to monitor while working:

```bash
# Using tmux for split screen monitoring
tmux new-session -s monitor 'tail -f ~/monitor_logs/dual_monitor_log_$(date +%Y-%m-%d).txt'
tmux split-window -v 'top'
tmux attach -t monitor
```

## 📊 Data Visualization

### Creating HTML Reports

You can create simple HTML reports from your monitoring data:

```bash
cat ~/monitor_logs/dual_monitor_log_$(date +%Y-%m-%d).txt | \
awk -F'|' '{print "<tr><td>"$2"</td><td>"$3"</td><td>"$4"</td><td>"$5"</td><td>"$6"</td><td>"$7"</td><td>"$8"</td><td>"$9"</td><td>"$10"</td></tr>"}' > \
/tmp/monitor_table.html

# Then add HTML header/footer and styling
```

### Setting Up Text-Based Dashboards

For terminal lovers, you can use tools like [wtfutil](https://wtfutil.com/) to create dashboards:

```bash
brew install wtfutil
# Then create a config that reads from your log files
```

---

Remember that for basic setup and daily usage instructions, refer to the main [README.md](README.md). This advanced guide is intended for users who want to customize and extend their Mac System Monitor experience.
