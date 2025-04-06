# Mac System Monitor Architecture

This document provides an overview of the Mac System Monitor project architecture to help new contributors understand the codebase structure and components.

## Overview

Mac System Monitor is a lightweight system monitoring tool for macOS that collects metrics, logs them, and provides alerts for abnormal conditions. The project follows a modular design with clear separation of concerns.

## Component Structure

```
Mac System Monitor
├── Core Monitoring Script
│   └── monitor_status.sh (Main monitoring functionality)
├── Installation & Management
│   ├── install_monitor.sh (Installation script)
│   ├── restart_monitor.sh (Service management)
│   └── uninstall_monitor.sh (Complete removal)
├── Testing
│   └── test_monitor.sh (Diagnostic testing)
└── Configuration Templates
    ├── com.user.monitorlogger.plist.template (LaunchAgent template)
    └── restart_service.sh.template (Utility script template)
```

## Core Components

### 1. Monitoring Service (`monitor_status.sh`)

This is the heart of the application that runs as a background process (LaunchAgent). The script:

- Collects system metrics at regular intervals
- Logs the information to daily log files
- Detects abnormal conditions and provides alerts
- Manages log rotation and cleanup

The monitoring loop is structured in logical sections:
- Setup and configuration
- System metrics collection 
- Data processing
- Alert detection
- Logging

### 2. Installation System (`install_monitor.sh`)

Handles the complete setup process:
- Creates necessary directories
- Installs dependencies
- Sets up LaunchAgent configuration from template
- Configures GPU temperature monitoring (optional)
- Creates utility scripts

### 3. Management Scripts

- `restart_monitor.sh`: Updates and restarts the service
- `uninstall_monitor.sh`: Removes the service and its files
- `test_monitor.sh`: Tests available metrics on the system

### 4. Templates

- `com.user.monitorlogger.plist.template`: Template for the LaunchAgent configuration
- `restart_service.sh.template`: Template for the service restart utility

## Data Flow

1. The LaunchAgent loads the monitoring script at startup
2. The script collects system metrics at regular intervals (default: 30 seconds)
3. Metrics are processed and compared against thresholds
4. If thresholds are exceeded, alerts are triggered
5. All data is logged to daily log files
6. Log files are automatically rotated and cleaned up

## Extension Points

The project can be extended in several ways:

1. **Additional Metrics**: New metrics can be added to the `monitor_status.sh` script
2. **Custom Alerts**: Thresholds and alert mechanisms can be customized
3. **Alternative Notification Methods**: The notification system can be extended
4. **Web UI**: A web interface could be added for visualization
5. **Remote Monitoring**: Support for monitoring remote systems could be added

## Testing Strategy

Testing is primarily handled through the `test_monitor.sh` script, which:
- Checks for required dependencies
- Tests each metric collection method
- Provides detailed output about what's working and what's not
- Suggests solutions for missing metrics

## Contribution Opportunities

Good places to start contributing:
1. Improving metric collection for specific Mac models
2. Adding new metrics (network, disk I/O, etc.)
3. Enhancing the alerting system
4. Adding visualization capabilities
5. Improving documentation

## Version Control

We use semantic versioning (MAJOR.MINOR.PATCH):
- MAJOR version for incompatible API changes
- MINOR version for backward-compatible feature additions
- PATCH version for backward-compatible bug fixes

All changes are documented in the CHANGELOG.md file.
