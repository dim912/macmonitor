#!/bin/bash
#
# Mac System Monitor - Test Script
# 
# This script tests the available system metrics on your Mac without installing anything.
# It helps diagnose which metrics can be captured by the monitor_status.sh script.
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

# Print header
echo -e "${BLUE}=== Mac System Monitor Test ===${NC}"
echo "This will check what system metrics are available on your Mac."
echo "The test doesn't install anything - it just identifies what your system can report."
echo ""

# Set PATH to include common locations for executables
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/usr/local/sbin:/opt/homebrew/sbin:$PATH"

# Find paths for required tools
OSX_CPU_TEMP_PATH=$(which osx-cpu-temp 2>/dev/null || echo "")
ISTATS_PATH=$(which istats 2>/dev/null || echo "")
POWERMETRICS_PATH=$(which powermetrics 2>/dev/null || echo "/usr/bin/powermetrics")

#----------------------------------------
# CHECK DEPENDENCIES
#----------------------------------------

echo -e "${BLUE}=== Checking for Dependencies ===${NC}"
echo "osx-cpu-temp: $(if [ -n "$OSX_CPU_TEMP_PATH" ]; then echo "Found at $OSX_CPU_TEMP_PATH"; else echo "Not found"; fi)"
echo "istats: $(if [ -n "$ISTATS_PATH" ]; then echo "Found at $ISTATS_PATH"; else echo "Not found"; fi)"
echo "powermetrics: $(if [ -n "$POWERMETRICS_PATH" ]; then echo "Found at $POWERMETRICS_PATH"; else echo "Not found"; fi)"
echo ""

#----------------------------------------
# TEST AVAILABLE METRICS
#----------------------------------------

echo -e "${BLUE}=== Testing Available Metrics ===${NC}"

# 1. CPU Temperature - try osx-cpu-temp first, fallback to system_profiler
echo -n "CPU Temperature: "
if [ -n "$OSX_CPU_TEMP_PATH" ]; then
    CPU_TEMP=$("$OSX_CPU_TEMP_PATH" 2>/dev/null || echo "N/A")
    if [ "$CPU_TEMP" != "N/A" ]; then
        echo -e "${GREEN}$CPU_TEMP${NC} (via osx-cpu-temp)"
    else
        echo -e "${YELLOW}N/A${NC} (osx-cpu-temp failed)"
    fi
else
    # Try alternative method
    CPU_TEMP=$(system_profiler SPPowerDataType 2>/dev/null | grep -i "CPU die temperature" | awk -F ':' '{print $2}' | xargs || echo "N/A")
    if [ "$CPU_TEMP" != "N/A" ]; then
        echo -e "${GREEN}$CPU_TEMP${NC} (via system_profiler)"
    else
        echo -e "${RED}N/A${NC} (osx-cpu-temp not installed and system_profiler failed)"
    fi
fi

# 2. GPU Temperature - try multiple methods
echo -n "GPU Temperature: "
GPU_FOUND=false

# Method 1: Try powermetrics with passwordless sudo (-n flag)
if [ -n "$POWERMETRICS_PATH" ]; then
    # First try with passwordless sudo
    GPU_TEMP=$(sudo -n "$POWERMETRICS_PATH" --samplers smc -n1 2>/dev/null | grep -i "GPU die temperature" | awk -F ':' '{print $2}' | xargs)
    if [ -n "$GPU_TEMP" ]; then
        echo -e "${GREEN}$GPU_TEMP${NC} (via passwordless sudo powermetrics)"
        GPU_FOUND=true
    else
        # Fallback to regular non-sudo method (which usually fails)
        GPU_TEMP=$("$POWERMETRICS_PATH" --samplers smc -n1 2>/dev/null | grep -i "GPU die temperature" | awk -F ':' '{print $2}' | xargs)
        if [ -n "$GPU_TEMP" ]; then
            echo -e "${GREEN}$GPU_TEMP${NC} (via powermetrics)"
            GPU_FOUND=true
        fi
    fi
fi

# Method 2: Try system_profiler as fallback
if [ "$GPU_FOUND" = false ]; then
    GPU_TEMP_ALT=$(system_profiler SPDisplaysDataType 2>/dev/null | grep -i "Temperature" | head -n1 | awk -F ':' '{print $2}' | xargs || echo "")
    if [ -n "$GPU_TEMP_ALT" ]; then
        echo -e "${GREEN}$GPU_TEMP_ALT${NC} (via system_profiler)"
        GPU_FOUND=true
    fi
fi

# If all methods failed
if [ "$GPU_FOUND" = false ]; then
    echo -e "${YELLOW}N/A${NC} (requires sudo privileges for powermetrics)"
    echo "  Note: Run ./quickfix_gpu.sh to enable GPU temperature monitoring"
fi

# 3. Fan Speed
echo -n "Fan Speed: "
if [ -n "$ISTATS_PATH" ]; then
    FAN_SPEED=$("$ISTATS_PATH" fan speed 2>/dev/null | grep "Fan 0" | awk -F ':' '{print $2}' | xargs || echo "N/A")
    if [ -n "$FAN_SPEED" ] && [ "$FAN_SPEED" != "N/A" ]; then
        echo -e "${GREEN}$FAN_SPEED${NC} (via iStats)"
    else
        echo -e "${YELLOW}N/A${NC} (not reported by iStats on this Mac model)"
    fi
else
    echo -e "${YELLOW}N/A${NC} (iStats not installed)"
fi

# 4. Other system metrics (these usually work on all Macs)
echo -e "\n${BLUE}Basic System Metrics (should work on all Macs):${NC}"

# WindowServer Usage
WINDOWSERVER_USAGE=$(ps -A -o %cpu,command | grep -i "WindowServer" | awk '{sum += $1} END {print sum}')
echo -e "WindowServer CPU: ${GREEN}$WINDOWSERVER_USAGE%${NC}"

# Swap Usage
SWAP_USED=$(/usr/sbin/sysctl vm.swapusage | awk '{print $7}')
echo -e "Swap Used: ${GREEN}$SWAP_USED${NC}"

# Memory Pressure
MEM_PRESSURE_RAW=$(memory_pressure 2>/dev/null | grep "System-wide memory free" | awk '{print $NF}' || echo "")
if [[ -z "$MEM_PRESSURE_RAW" ]]; then
    # Alternative method
    MEM_USED_PCT=$(vm_stat | grep "Pages active" | awk '{print $3}' | sed 's/\.//')
    echo -e "Memory Status: ${GREEN}${MEM_USED_PCT:-Unknown}%${NC} (via vm_stat)"
else
    echo -e "Memory Status: ${GREEN}$MEM_PRESSURE_RAW${NC} (via memory_pressure)"
fi

#----------------------------------------
# SUMMARY
#----------------------------------------

echo -e "\n${GREEN}Test complete!${NC}"

# Count available metrics
AVAILABLE=0
[ "$CPU_TEMP" != "N/A" ] && ((AVAILABLE++))
[ "$GPU_FOUND" = true ] && ((AVAILABLE++)) 
[ "$FAN_SPEED" != "N/A" ] && [ "$FAN_SPEED" != "" ] && ((AVAILABLE++))
((AVAILABLE+=3)) # WindowServer, Swap, Memory are always available

echo -e "\nSummary: $AVAILABLE out of 6 metrics are available on your system."
echo "Note: The monitoring service will show N/A for unavailable metrics."
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "  1. To install the monitoring service: ./install_monitor.sh"
echo "  2. To view the README for more info: open README.md"
