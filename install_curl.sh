#!/bin/bash
#
# Mac System Monitor - One-line Installer
# 
# This script downloads and installs Mac System Monitor in one step

# Color definitions
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Mac System Monitor One-line Installer ===${NC}"

# Create temporary directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Download and extract latest version
echo -e "${BLUE}Downloading Mac System Monitor...${NC}"
curl -sL https://github.com/user/mac-system-monitor/archive/main.tar.gz -o mac-monitor.tar.gz
tar -xzf mac-monitor.tar.gz
cd mac-system-monitor-main

# Run installer
echo -e "${BLUE}Running installer...${NC}"
chmod +x install_monitor.sh
./install_monitor.sh

# Clean up
cd ~
rm -rf "$TEMP_DIR"

echo -e "${GREEN}✅ Mac System Monitor has been installed successfully!${NC}"
echo -e "${GREEN}Run 'tail -f ~/monitor_logs/dual_monitor_log_\$(date +%Y-%m-%d).txt' to see your stats.${NC}"
