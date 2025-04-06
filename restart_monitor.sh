#!/bin/bash
#
# Mac System Monitor - Restart Script
# 
# This script updates the monitoring service with the latest version of monitor_status.sh.
# It copies the script to the monitor directory and restarts the service.
#

#----------------------------------------
# SETUP
#----------------------------------------

# Color definitions for terminal output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Mac System Monitor Restart ===${NC}"
echo "This script will update the monitoring service with the latest script."

#----------------------------------------
# CHECK INSTALLATION
#----------------------------------------

# Ensure the monitor directory exists
MONITOR_DIR="$HOME/.monitor"
if [ ! -d "$MONITOR_DIR" ]; then
    echo -e "${YELLOW}Monitor not installed. Installing for the first time...${NC}"
    ./install_monitor.sh
    exit 0
fi

# Verify the source script exists
if [ ! -f "$(dirname "$0")/monitor_status.sh" ]; then
    echo -e "${RED}Error: monitor_status.sh not found in current directory.${NC}"
    echo "This script must be run from the same directory as monitor_status.sh."
    exit 1
fi

#----------------------------------------
# UPDATE SCRIPT
#----------------------------------------

# Copy the latest monitoring script
echo -e "${BLUE}Updating monitoring script...${NC}"
cp "$(dirname "$0")/monitor_status.sh" "$MONITOR_DIR/"
chmod +x "$MONITOR_DIR/monitor_status.sh"

#----------------------------------------
# RESTART SERVICE
#----------------------------------------

# Restart the monitoring service
echo -e "${BLUE}Restarting monitor service...${NC}"
UTILS_SCRIPT="$MONITOR_DIR/utils/restart_service.sh"

# Try to use the utility script first
if [ -f "$UTILS_SCRIPT" ]; then
    "$UTILS_SCRIPT"
    RESTART_STATUS=$?
else
    # Fallback method if utility script is not found
    echo -e "${YELLOW}Utility script not found. Using fallback restart method...${NC}"
    
    # Get current username
    USERNAME=$(whoami)
    PLIST_PATH="$HOME/Library/LaunchAgents/com.$USERNAME.monitorlogger.plist"
    
    # Check if LaunchAgent exists
    if [ ! -f "$PLIST_PATH" ]; then
        echo -e "${RED}No LaunchAgent found at $PLIST_PATH${NC}"
        echo -e "${YELLOW}Please run install_monitor.sh first.${NC}"
        exit 1
    fi

    # Restart the service
    launchctl unload "$PLIST_PATH" 2>/dev/null
    sleep 1
    launchctl load -w "$PLIST_PATH"
    RESTART_STATUS=$?
fi

#----------------------------------------
# COMPLETION
#----------------------------------------

# Display status
if [ $RESTART_STATUS -eq 0 ]; then
    echo -e "${GREEN}Monitor successfully updated and restarted!${NC}"
else
    echo -e "${YELLOW}The monitor was updated but there might have been an issue restarting it.${NC}"
fi

# Provide helpful diagnostic commands
echo ""
echo -e "${BLUE}Diagnostic Information:${NC}"
echo "  View startup log:     cat $HOME/monitor_logs/monitor_startup.log"
echo "  Check service status: launchctl list | grep monitorlogger"
echo "  View monitoring data: tail -n 20 $HOME/monitor_logs/dual_monitor_log_$(date +%Y-%m-%d).txt"
echo ""
echo -e "${YELLOW}Note:${NC} Allow a few seconds for the service to start collecting new data."
