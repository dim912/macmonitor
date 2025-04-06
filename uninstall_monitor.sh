#!/bin/bash
#
# Mac System Monitor - Uninstaller
# 
# This script completely removes the monitoring service from your system.
# It stops the service, removes the LaunchAgent, and deletes all monitoring files.
# Log files are preserved by default but can be removed manually.
#

#----------------------------------------
# SETUP
#----------------------------------------

# Color definitions for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Mac System Monitor Uninstaller ===${NC}"
echo "This will remove the monitoring service from your system."

#----------------------------------------
# STOP AND REMOVE SERVICE
#----------------------------------------

# Get current username and LaunchAgent path
USERNAME=$(whoami)
PLIST_PATH="$HOME/Library/LaunchAgents/com.$USERNAME.monitorlogger.plist"
SERVICE_FOUND=false

# Stop and remove the LaunchAgent if found
if [ -f "$PLIST_PATH" ]; then
    echo -e "${BLUE}Stopping monitor service...${NC}"
    launchctl unload "$PLIST_PATH" 2>/dev/null
    
    echo -e "${BLUE}Removing LaunchAgent configuration...${NC}"
    rm -f "$PLIST_PATH"
    SERVICE_FOUND=true
fi

# Notify if no service was found
if [ "$SERVICE_FOUND" = false ]; then
    echo -e "${YELLOW}No active monitoring service found.${NC}"
fi

#----------------------------------------
# REMOVE FILES
#----------------------------------------

# Remove the monitor scripts and utilities
echo -e "${BLUE}Removing monitor files...${NC}"
rm -rf "$HOME/.monitor"

#----------------------------------------
# COMPLETION
#----------------------------------------

echo -e "${GREEN}Monitor uninstalled successfully!${NC}"
echo ""
echo -e "${YELLOW}Note:${NC} Log files in $HOME/monitor_logs have been preserved."
echo "To remove all logs run: rm -rf $HOME/monitor_logs"
