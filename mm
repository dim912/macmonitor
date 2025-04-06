#!/bin/bash

# Mac System Monitor - Command Line Interface
# This script provides a unified command interface for Mac System Monitor

# Color definitions
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

COMMAND=$1
shift 1

case "$COMMAND" in
  show)
    # Default number of entries to show
    LIMIT=20
    
    # Parse parameters
    while [[ $# -gt 0 ]]; do
      case "$1" in
        -l|--limit)
          if [[ "$2" =~ ^[0-9]+$ && "$2" -gt 0 ]]; then
            LIMIT="$2"
            shift 2
          else
            echo "Error: -l/--limit requires a positive number"
            exit 1
          fi
          ;;
        *)
          echo "Unknown parameter: $1"
          exit 1
          ;;
      esac
    done
    
    # Show stats in CLI with auto-update
    echo -e "${BLUE}Showing system stats with auto-update (limit: ${LIMIT} entries, press Ctrl+C to exit)...${NC}"
    
    # Define the header with color - exactly matching data width with added spaces for alignment
    YELLOW='\033[0;33m'
    HEADER="${YELLOW}| Timestamp           |   CPU  |   GPU  | WS CPU  |   Memory    |    Swap   |    Fan   |     Uptime     |      Alerts      |${NC}"
    SEPARATOR="${YELLOW}|---------------------|--------|--------|---------|-------------|-----------|----------|----------------|------------------|${NC}"
    
    # Check if watch command is available
    if command -v watch &> /dev/null; then
      # For watch, we need to use plain text headers without color codes as watch may not handle them correctly
      # Our format_columns.awk script now generates appropriately sized columns
      # Based on actual data. We'll let it generate the entire output including headers.
      SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
      
      # Create a header template file for the AWK script to use
      HEADER_FILE="/tmp/mmheader.txt"
      echo "| Timestamp | CPU | GPU | WS CPU | Memory | Swap | Fan | Uptime | Alerts |" > $HEADER_FILE
      echo "|-----------|-----|-----|--------|--------|------|-----|--------|--------|" >> $HEADER_FILE
      
      # Sort by most recent and pass to formatter - refresh every 30 seconds
      # Note: watch command's header already shows seconds until next update
      watch -n 30 "cat $HEADER_FILE ~/monitor_logs/dual_monitor_log_\$(date +%Y-%m-%d).txt 2>/dev/null | sort -r | head -n $((${LIMIT}+2)) | \"${SCRIPT_DIR}/format_columns.awk\""
    else
      # Fallback if watch is not available - with next refresh time based on log entry
      while true; do
        # Clear screen once and display the data with headers
        clear
        
        # Create a header template file for the AWK script to use
        HEADER_FILE="/tmp/mmheader.txt"
        echo "| Timestamp | CPU | GPU | WS CPU | Memory | Swap | Fan | Uptime | Alerts |" > $HEADER_FILE
        echo "|-----------|-----|-----|--------|--------|------|-----|--------|--------|" >> $HEADER_FILE
        
        # Format data with dynamically sized columns
        SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
        LOG_DATA=$(cat $HEADER_FILE ~/monitor_logs/dual_monitor_log_$(date +%Y-%m-%d).txt 2>/dev/null | sort -r | head -n $((${LIMIT}+2)) | "${SCRIPT_DIR}/format_columns.awk")
        
        # Extract the most recent timestamp from the data (skip header rows)
        REAL_DATA=$(echo "$LOG_DATA" | tail -n +3)
        if [ -n "$REAL_DATA" ]; then
          RECENT_TIMESTAMP=$(echo "$REAL_DATA" | head -n 1 | cut -d'|' -f2 | xargs)
          
          # Parse the timestamp and calculate the next refresh time (current log time + 30 sec)
          # Convert YYYY-MM-DD HH:MM:SS to seconds since epoch
          TIMESTAMP_SECONDS=$(date -j -f "%Y-%m-%d %H:%M:%S" "$RECENT_TIMESTAMP" +%s 2>/dev/null)
          if [ -n "$TIMESTAMP_SECONDS" ]; then
            # Add 30 seconds for next refresh
            NEXT_REFRESH_SECONDS=$((TIMESTAMP_SECONDS + 30))
            NEXT_REFRESH=$(date -r $NEXT_REFRESH_SECONDS +%H:%M:%S)
            
            # Get the time difference to sleep
            CURRENT_SECONDS=$(date +%s)
            SLEEP_DURATION=$((NEXT_REFRESH_SECONDS - CURRENT_SECONDS))
            
            # Ensure sleep duration is positive, default to 30 seconds if issues occur
            if [ $SLEEP_DURATION -le 0 ]; then
              SLEEP_DURATION=30
              NEXT_REFRESH=$(date -v+${SLEEP_DURATION}S +%H:%M:%S)
            fi
          else
            # Fallback if date parsing fails
            SLEEP_DURATION=30
            NEXT_REFRESH=$(date -v+${SLEEP_DURATION}S +%H:%M:%S)
          fi
        else
          # No log data found, use default
          RECENT_TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
          SLEEP_DURATION=30
          NEXT_REFRESH=$(date -v+${SLEEP_DURATION}S +%H:%M:%S)
        fi
        
        echo -e "${BLUE}Mac System Monitor - Live Stats (Updated: ${RECENT_TIMESTAMP})${NC}"
        echo -e "${BLUE}Next refresh at ${NEXT_REFRESH}. Press Ctrl+C to exit.${NC}\n"
        
        # Display the formatted data (already includes headers)
        echo "$LOG_DATA"
        
        # Wait until the calculated next refresh time
        sleep $SLEEP_DURATION
      done
    fi
    ;;
  help)
    # Display help information for all commands
    echo -e "${GREEN}Mac System Monitor - Command Line Interface${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo ""
    echo "USAGE: ./mm [command] [options]"
    echo ""
    echo -e "${YELLOW}Available Commands:${NC}"
    echo ""
    echo -e "${BLUE}show${NC} [-l|--limit N]"
    echo "    Show system stats in CLI with auto-update."
    echo "    Options:"
    echo "      -l, --limit N    Show N most recent entries (default: 20)"
    echo "    Examples:"
    echo "      ./mm show              # Show default 20 entries"
    echo "      ./mm show -l 100       # Show 100 most recent entries"
    echo ""
    echo -e "${BLUE}config${NC} [list|set|reset]"
    echo "    Configure alert thresholds and alert management settings."
    echo "    Options:"
    echo "      list                  Show current thresholds and alert settings"
    echo "      set <param> <value>   Set a specific threshold or setting"
    echo "      reset                 Reset all thresholds to defaults"
    echo "    Parameter groups:"
    echo "      Standard thresholds:  cpu, gpu, wscpu, swap, fan, memory, streak"
    echo "      Alert management:     beeps, cooldown, severity"
    echo "      Boolean settings:     dnd (on/off), smart (on/off)"
    echo "      Time settings:        dnd-start (HH:MM), dnd-end (HH:MM)"
    echo "    Examples:"
    echo "      ./mm config list           # Show all current settings"
    echo "      ./mm config set cpu 80     # Set CPU temp threshold to 80°C"
    echo "      ./mm config set beeps 1    # Set alert beep count to 1"
    echo "      ./mm config set dnd on     # Enable Do Not Disturb mode"
    echo "      ./mm config set severity 2 # Set minimum alert severity (1=Low, 2=Medium, 3=High)"
    echo ""
    echo -e "${BLUE}test${NC}"
    echo "    Test what metrics are available on your system."
    echo "    Useful for troubleshooting if some metrics show as N/A."
    echo "    Example: ./mm test"
    echo ""
    echo -e "${BLUE}restart${NC}"
    echo "    Start or restart the monitoring service."
    echo "    This will create or update the LaunchAgent for automatic startup."
    echo "    Example: ./mm restart"
    echo ""
    echo -e "${BLUE}uninstall${NC}"
    echo "    Remove the monitoring service."
    echo "    This stops data collection and removes the startup service."
    echo "    Example: ./mm uninstall"
    echo ""
    echo -e "${BLUE}help${NC}"
    echo "    Display this help information."
    echo "    Example: ./mm help"
    echo ""
    echo "For more detailed information, see the README.md file."
    echo ""
    ;;
  test)
    # Test available metrics
    echo -e "${BLUE}Testing available metrics...${NC}"
    ./test_monitor.sh "$@"
    ;;
  restart)
    # Restart monitoring service
    echo -e "${BLUE}Restarting monitoring service...${NC}"
    ./restart_monitor.sh "$@"
    ;;
  uninstall)
    # Uninstall the service
    echo -e "${BLUE}Uninstalling monitoring service...${NC}"
    ./uninstall_monitor.sh "$@"
    ;;
  config)
    # Configure alert thresholds
    ./config_thresholds.sh "$@"
    ;;
  *)
    echo -e "${GREEN}Mac System Monitor - System Monitoring Tool${NC}"
    echo ""
    echo "Usage: ./mm [command] [options]"
    echo ""
    echo "Commands:"
    echo "  show                 Show stats in CLI with auto-update"
    echo "    Options:"
    echo "      -l, --limit N    Show N most recent entries (default: 20)"
    echo "      Example: ./mm show -l 100"
    echo ""
    echo "  config               Configure alert thresholds and alert management"
    echo "  test                 Test available metrics"
    echo "  restart              Start/restart monitoring service"
    echo "  uninstall            Remove the monitoring service"
    echo "  help                 Display detailed help information"
    echo ""
    echo "For detailed help, run: ./mm help"
    echo ""
    ;;
esac
