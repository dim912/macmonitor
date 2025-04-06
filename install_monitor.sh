#!/bin/bash
#
# Mac System Monitor - Installer
# 
# This script installs the monitoring service on your Mac.
# It sets up the monitor script, installs dependencies,
# and configures the service to run at startup.
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

echo -e "${BLUE}=== Mac System Monitor Installer ===${NC}"
echo "This script will install a system monitoring tool that logs:"
echo "  - CPU & GPU temperatures"
echo "  - Fan speeds"
echo "  - Memory usage"
echo "  - System alerts"
echo ""

#----------------------------------------
# CREATE DIRECTORIES & COPY FILES
#----------------------------------------

# Create .monitor directory in home folder
echo -e "${BLUE}Setting up monitor directory...${NC}"
MONITOR_DIR="$HOME/.monitor"
mkdir -p "$MONITOR_DIR"

# Copy monitor script to .monitor directory
echo -e "${BLUE}Installing monitoring script...${NC}"
cp "$(dirname "$0")/monitor_status.sh" "$MONITOR_DIR/"
chmod +x "$MONITOR_DIR/monitor_status.sh"

#----------------------------------------
# INSTALL DEPENDENCIES
#----------------------------------------

echo -e "${BLUE}Checking for required dependencies...${NC}"

# Check for Homebrew
if ! command -v brew &> /dev/null; then
    echo -e "${YELLOW}Homebrew not found. Installing...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for this session
    if [[ $(uname -m) == 'arm64' ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/usr/local/bin/brew shellenv)"
    fi
else
    echo -e "${GREEN}Homebrew already installed.${NC}"
fi

# Install osx-cpu-temp
if ! command -v osx-cpu-temp &> /dev/null; then
    echo -e "${YELLOW}Installing osx-cpu-temp...${NC}"
    brew install osx-cpu-temp
else
    echo -e "${GREEN}osx-cpu-temp already installed.${NC}"
fi

# Install iStats
if ! gem list -i "iStats" &> /dev/null; then
    echo -e "${YELLOW}Installing iStats gem...${NC}"
    sudo gem install iStats
else
    echo -e "${GREEN}iStats already installed.${NC}"
fi

# Set up LaunchAgent
echo -e "${BLUE}Setting up LaunchAgent...${NC}"

# Set user-specific paths
USERNAME=$(whoami)
PLIST_PATH="$HOME/Library/LaunchAgents/com.$USERNAME.monitorlogger.plist"

# Check if LaunchAgent already exists
if [ -f "$PLIST_PATH" ]; then
    echo -e "${GREEN}Found existing LaunchAgent: $PLIST_PATH${NC}"
else
    echo -e "${BLUE}Creating new LaunchAgent: $PLIST_PATH${NC}"
fi

# Stop any running monitor first
RUNNING_LABEL=$(plutil -p "$PLIST_PATH" 2>/dev/null | grep "Label" | cut -d\" -f4)
if [ -n "$RUNNING_LABEL" ]; then
    echo -e "${BLUE}Stopping existing monitor process...${NC}"
    launchctl unload "$PLIST_PATH" 2>/dev/null
fi

# Create or update plist file
echo -e "${BLUE}Updating LaunchAgent configuration...${NC}"
mkdir -p "$HOME/Library/LaunchAgents"

# Create LaunchAgent plist file from template
echo -e "${BLUE}Creating LaunchAgent from template...${NC}"
# Read the template and replace placeholders with actual values
sed -e "s/USERNAME/$USERNAME/g" \
    -e "s|MONITOR_DIR|$MONITOR_DIR|g" \
    "$(dirname "$0")/com.user.monitorlogger.plist.template" > "$PLIST_PATH"

# Ensure proper permissions
chmod 644 "$PLIST_PATH"

# Load updated LaunchAgent
echo -e "${BLUE}Starting monitor service...${NC}"
launchctl load -w "$PLIST_PATH"

# Verify it's running
sleep 1
if launchctl list | grep -q "com.$USERNAME.monitorlogger"; then
    echo -e "${GREEN}Monitor service started successfully!${NC}"
else
    echo -e "${YELLOW}Monitor service may not have started properly. Check logs for details.${NC}"
fi

#----------------------------------------
# CONFIGURE GPU TEMPERATURE ACCESS
#----------------------------------------

# Ask user if they want to set up GPU temperature monitoring
echo ""
echo -e "${BLUE}GPU Temperature Monitoring Setup${NC}"
echo "GPU temperature monitoring requires sudo access for the powermetrics command."
echo "Would you like to set up passwordless sudo access for GPU temperature monitoring?"
echo "This requires administrator privileges to add a sudoers configuration."
echo ""
read -p "Set up GPU temperature monitoring? (y/n): " SETUP_GPU

if [[ "$SETUP_GPU" == "y" || "$SETUP_GPU" == "Y" ]]; then
    echo -e "${BLUE}Testing GPU temperature access...${NC}"
    GPU_TEST=$(sudo powermetrics --samplers smc -n1 2>/dev/null | grep -i "GPU die temperature")
    
    if [ -n "$GPU_TEST" ]; then
        echo -e "${GREEN}Good news! Sudo access to powermetrics works.${NC}"
        
        # Create temporary sudoers file
        SUDOERS_CONTENT="# Allow user $USERNAME to run powermetrics without password for GPU temperature monitoring
$USERNAME ALL=(ALL) NOPASSWD: /usr/bin/powermetrics"
        
        echo -e "${BLUE}Setting up passwordless sudo for powermetrics...${NC}"
        echo "$SUDOERS_CONTENT" | sudo tee /etc/sudoers.d/10-powermetrics > /dev/null
        
        if [ $? -eq 0 ]; then
            sudo chmod 440 /etc/sudoers.d/10-powermetrics
            echo -e "${GREEN}GPU temperature access configured successfully!${NC}"
            
            # Test if it works without password
            TEST_RESULT=$(sudo -n powermetrics --samplers smc -n1 2>/dev/null | grep -i "GPU die temperature")
            if [ -n "$TEST_RESULT" ]; then
                echo -e "${GREEN}Verified: passwordless access is working.${NC}"
                echo "$TEST_RESULT"
            else
                echo -e "${YELLOW}Something went wrong with passwordless access setup.${NC}"
                echo "You can try running test_monitor.sh to check what metrics are available."
            fi
        else
            echo -e "${RED}Failed to configure sudo access.${NC}"
            echo "You may need to manually configure sudo access for powermetrics."
        fi
    else
        echo -e "${RED}Could not access GPU temperature even with sudo.${NC}"
        echo "This might mean your Mac doesn't expose GPU temperature data or the command is not accessible."
    fi
else
    echo -e "${YELLOW}Skipping GPU temperature setup.${NC}"
    echo "You can always set it up later by running test_monitor.sh to check what's missing."
fi

echo -e "${GREEN}Monitor installed and started!${NC}"
echo "Logs will be available in: $HOME/monitor_logs"
echo ""
echo -e "${YELLOW}Notes:${NC}"
echo "1. View the startup log at $HOME/monitor_logs/monitor_startup.log for any issues."
echo "2. To uninstall, run the uninstall_monitor.sh script."

#----------------------------------------
# CREATE UTILITY SCRIPTS
#----------------------------------------

# Create service utility scripts directory
echo -e "${BLUE}Creating utility scripts...${NC}"
mkdir -p "$MONITOR_DIR/utils"

# Create utility script from template
cp "$(dirname "$0")/restart_service.sh.template" "$MONITOR_DIR/utils/restart_service.sh"

chmod +x "$MONITOR_DIR/utils/restart_service.sh"

#----------------------------------------
# COMPLETION
#----------------------------------------

echo -e "${GREEN}✨ Installation complete! Your Mac is now being monitored. ✨${NC}"
echo ""
echo -e "${BLUE}📊 View Your System Stats:${NC}"
echo -e "  ${GREEN}tail -f $HOME/monitor_logs/dual_monitor_log_$(date +%Y-%m-%d).txt${NC}"
echo "    This shows a live feed of your system metrics - try it now!"
echo ""
echo -e "${BLUE}📚 Available Documentation:${NC}"
echo "  - README.md       - General information and troubleshooting"
echo "  - USAGE_GUIDE.md  - Detailed usage instructions and tips"
echo ""
echo -e "${BLUE}🛠 Management Scripts:${NC}"
echo "  - $(dirname "$0")/restart_monitor.sh   (Update the script & restart service)"
echo "  - $(dirname "$0")/test_monitor.sh      (Test available system metrics)"
echo "  - $(dirname "$0")/uninstall_monitor.sh (Remove the monitoring service)"
echo ""
echo -e "${YELLOW}💡 Quick Tips:${NC}"
echo "  1. View live stats:    ${GREEN}tail -f $HOME/monitor_logs/dual_monitor_log_$(date +%Y-%m-%d).txt${NC}"
echo "  2. Check last entries: ${GREEN}tail -n 20 $HOME/monitor_logs/dual_monitor_log_$(date +%Y-%m-%d).txt${NC}"
echo "  3. View alerts only:   ${GREEN}grep \"\\[\" $HOME/monitor_logs/dual_monitor_log_$(date +%Y-%m-%d).txt${NC}"
echo ""
echo -e "${GREEN}Enjoy your Mac System Monitor! 🖥️${NC}"
