#!/bin/bash
#
# Mac System Monitor - Configuration Script
# This script creates or updates the threshold configuration

# Determine the monitor config directory
CONFIG_DIR="$HOME/.monitor"
CONFIG_FILE="$CONFIG_DIR/thresholds.conf"

# Create config directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

# Function to create default config if not exists
create_default_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        cat > "$CONFIG_FILE" << EOF
# Mac System Monitor Alert Thresholds
# Created: $(date)
# Modify these values to customize when alerts are triggered

# Temperature thresholds (in °C)
CPU_TEMP_THRESHOLD=85
GPU_TEMP_THRESHOLD=85

# CPU usage threshold for WindowServer (percentage)
WS_CPU_THRESHOLD=50

# Swap usage threshold (in MB)
SWAP_THRESHOLD=500

# Fan speed threshold (in RPM)
FAN_SPEED_THRESHOLD=5000

# Memory pressure threshold (percentage)
MEMORY_THRESHOLD=90

# Consecutive readings required for memory alerts
LOW_MEM_STREAK_THRESHOLD=3

# Alert management settings
BEEP_COUNT=2                     # Number of beeps per alert
ALERT_COOLDOWN=10                # Minutes between alerts of same type
ALERT_SEVERITY_THRESHOLD=2       # Minimum severity level to show alerts (1=low, 2=medium, 3=high)
DND_MODE=false                   # Do Not Disturb mode (true/false)
DND_START_TIME="23:00"           # Start of Do Not Disturb window (24-hour format)
DND_END_TIME="07:00"             # End of Do Not Disturb window (24-hour format)
SMART_THRESHOLD_ENABLED=true     # Use adaptive thresholds based on system behavior
EOF
        echo "Created default configuration at $CONFIG_FILE"
    fi
}

# Function to display current thresholds
show_thresholds() {
    echo -e "\e[1;32mCurrent Alert Thresholds:\e[0m"
    echo "--------------------------"
    
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        echo "CPU Temperature:  > ${CPU_TEMP_THRESHOLD:-85}°C"
        echo "GPU Temperature:  > ${GPU_TEMP_THRESHOLD:-85}°C"
        echo "WindowServer CPU: > ${WS_CPU_THRESHOLD:-50}%"
        echo "Swap Usage:       > ${SWAP_THRESHOLD:-500}MB"
        echo "Fan Speed:        > ${FAN_SPEED_THRESHOLD:-5000} RPM"
        echo "Memory Pressure:  > ${MEMORY_THRESHOLD:-90}% (for ${LOW_MEM_STREAK_THRESHOLD:-3} consecutive readings)"
        
        echo ""
        echo -e "\e[1;32mAlert Management Settings:\e[0m"
        echo "--------------------------"
        echo "Beep Count:           ${BEEP_COUNT:-2} beeps"
        echo "Alert Cooldown:       ${ALERT_COOLDOWN:-10} minutes"
        
        # Display severity threshold in human-readable form
        severity="Medium"
        if [ "${ALERT_SEVERITY_THRESHOLD:-2}" = "1" ]; then
            severity="Low"
        elif [ "${ALERT_SEVERITY_THRESHOLD:-2}" = "3" ]; then
            severity="High"
        fi
        echo "Minimum Severity:     ${severity} (${ALERT_SEVERITY_THRESHOLD:-2})"
        
        # Display DND status
        dnd_status="Disabled"
        if [ "${DND_MODE:-false}" = "true" ]; then
            dnd_status="Enabled (${DND_START_TIME:-23:00} to ${DND_END_TIME:-07:00})"
        fi
        echo "Do Not Disturb:       ${dnd_status}"
        
        # Display smart threshold status
        smart_status="Disabled"
        if [ "${SMART_THRESHOLD_ENABLED:-true}" = "true" ]; then
            smart_status="Enabled"
        fi
        echo "Smart Thresholds:     ${smart_status}"
    else
        create_default_config
        show_thresholds
    fi
}

# Function to set a specific threshold
set_threshold() {
    local param="$1"
    local value="$2"
    
    # Create default config if it doesn't exist
    if [ ! -f "$CONFIG_FILE" ]; then
        create_default_config
    fi
    
    # Verify the parameter is valid
    case "$param" in
        # Standard alert thresholds (numeric)
        cpu|gpu|wscpu|swap|fan|memory|streak|beeps|cooldown|severity)
            # Input validation for numeric values
            if ! [[ "$value" =~ ^[0-9]+$ ]]; then
                echo "Error: Value must be a positive number."
                exit 1
            fi
            
            case "$param" in
                cpu)
                    if [ "$value" -lt 50 ] || [ "$value" -gt 110 ]; then
                        echo "Warning: CPU temperature threshold $value°C is outside normal range (50-110°C)"
                        read -p "Are you sure? (y/n): " -n 1 -r
                        echo
                        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                            exit 1
                        fi
                    fi
                    sed -i.bak '/CPU_TEMP_THRESHOLD=/d' "$CONFIG_FILE"
                    echo "CPU_TEMP_THRESHOLD=$value" >> "$CONFIG_FILE"
                    echo "CPU temperature threshold set to $value°C"
                    ;;
                gpu)
                    if [ "$value" -lt 50 ] || [ "$value" -gt 110 ]; then
                        echo "Warning: GPU temperature threshold $value°C is outside normal range (50-110°C)"
                        read -p "Are you sure? (y/n): " -n 1 -r
                        echo
                        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                            exit 1
                        fi
                    fi
                    sed -i.bak '/GPU_TEMP_THRESHOLD=/d' "$CONFIG_FILE"
                    echo "GPU_TEMP_THRESHOLD=$value" >> "$CONFIG_FILE"
                    echo "GPU temperature threshold set to $value°C"
                    ;;
                wscpu)
                    if [ "$value" -lt 20 ] || [ "$value" -gt 100 ]; then
                        echo "Warning: WindowServer CPU threshold $value% is outside normal range (20-100%)"
                        read -p "Are you sure? (y/n): " -n 1 -r
                        echo
                        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                            exit 1
                        fi
                    fi
                    sed -i.bak '/WS_CPU_THRESHOLD=/d' "$CONFIG_FILE"
                    echo "WS_CPU_THRESHOLD=$value" >> "$CONFIG_FILE"
                    echo "WindowServer CPU threshold set to $value%"
                    ;;
                swap)
                    sed -i.bak '/SWAP_THRESHOLD=/d' "$CONFIG_FILE"
                    echo "SWAP_THRESHOLD=$value" >> "$CONFIG_FILE"
                    echo "Swap usage threshold set to ${value}MB"
                    ;;
                fan)
                    if [ "$value" -lt 2000 ] || [ "$value" -gt 10000 ]; then
                        echo "Warning: Fan speed threshold $value RPM is outside normal range (2000-10000 RPM)"
                        read -p "Are you sure? (y/n): " -n 1 -r
                        echo
                        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                            exit 1
                        fi
                    fi
                    sed -i.bak '/FAN_SPEED_THRESHOLD=/d' "$CONFIG_FILE"
                    echo "FAN_SPEED_THRESHOLD=$value" >> "$CONFIG_FILE"
                    echo "Fan speed threshold set to $value RPM"
                    ;;
                memory)
                    if [ "$value" -lt 50 ] || [ "$value" -gt 100 ]; then
                        echo "Warning: Memory threshold $value% is outside normal range (50-100%)"
                        read -p "Are you sure? (y/n): " -n 1 -r
                        echo
                        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                            exit 1
                        fi
                    fi
                    sed -i.bak '/MEMORY_THRESHOLD=/d' "$CONFIG_FILE"
                    echo "MEMORY_THRESHOLD=$value" >> "$CONFIG_FILE"
                    echo "Memory pressure threshold set to $value%"
                    ;;
                streak)
                    if [ "$value" -lt 1 ] || [ "$value" -gt 10 ]; then
                        echo "Warning: Memory streak threshold $value readings is outside normal range (1-10 readings)"
                        read -p "Are you sure? (y/n): " -n 1 -r
                        echo
                        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                            exit 1
                        fi
                    fi
                    sed -i.bak '/LOW_MEM_STREAK_THRESHOLD=/d' "$CONFIG_FILE"
                    echo "LOW_MEM_STREAK_THRESHOLD=$value" >> "$CONFIG_FILE"
                    echo "Memory alert streak threshold set to $value consecutive readings"
                    ;;
                beeps)
                    if [ "$value" -lt 0 ] || [ "$value" -gt 10 ]; then
                        echo "Warning: Beep count $value is outside normal range (0-10)"
                        read -p "Are you sure? (y/n): " -n 1 -r
                        echo
                        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                            exit 1
                        fi
                    fi
                    sed -i.bak '/BEEP_COUNT=/d' "$CONFIG_FILE"
                    echo "BEEP_COUNT=$value" >> "$CONFIG_FILE"
                    echo "Alert beep count set to $value beeps"
                    ;;
                cooldown)
                    if [ "$value" -lt 1 ] || [ "$value" -gt 60 ]; then
                        echo "Warning: Alert cooldown $value minutes is outside normal range (1-60 minutes)"
                        read -p "Are you sure? (y/n): " -n 1 -r
                        echo
                        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                            exit 1
                        fi
                    fi
                    sed -i.bak '/ALERT_COOLDOWN=/d' "$CONFIG_FILE"
                    echo "ALERT_COOLDOWN=$value" >> "$CONFIG_FILE"
                    echo "Alert cooldown set to $value minutes"
                    ;;
                severity)
                    if [ "$value" -lt 1 ] || [ "$value" -gt 3 ]; then
                        echo "Error: Severity level must be between 1 and 3 (1=low, 2=medium, 3=high)"
                        exit 1
                    fi
                    local severity_text="Medium"
                    if [ "$value" = "1" ]; then
                        severity_text="Low"
                    elif [ "$value" = "3" ]; then
                        severity_text="High"
                    fi
                    sed -i.bak '/ALERT_SEVERITY_THRESHOLD=/d' "$CONFIG_FILE"
                    echo "ALERT_SEVERITY_THRESHOLD=$value" >> "$CONFIG_FILE"
                    echo "Minimum alert severity threshold set to $severity_text ($value)"
                    ;;
            esac
            ;;
        
        # Boolean settings
        dnd|smart)
            # Input validation for boolean values
            if [[ "$value" != "on" && "$value" != "off" && "$value" != "true" && "$value" != "false" ]]; then
                echo "Error: Value must be 'on/off' or 'true/false'."
                exit 1
            fi
            
            # Convert to true/false
            local bool_value="false"
            if [[ "$value" == "on" || "$value" == "true" ]]; then
                bool_value="true"
            fi
            
            case "$param" in
                dnd)
                    sed -i.bak '/DND_MODE=/d' "$CONFIG_FILE"
                    echo "DND_MODE=$bool_value" >> "$CONFIG_FILE"
                    if [ "$bool_value" = "true" ]; then
                        echo "Do Not Disturb mode enabled"
                    else
                        echo "Do Not Disturb mode disabled"
                    fi
                    ;;
                smart)
                    sed -i.bak '/SMART_THRESHOLD_ENABLED=/d' "$CONFIG_FILE"
                    echo "SMART_THRESHOLD_ENABLED=$bool_value" >> "$CONFIG_FILE"
                    if [ "$bool_value" = "true" ]; then
                        echo "Smart thresholds enabled"
                    else
                        echo "Smart thresholds disabled"
                    fi
                    ;;
            esac
            ;;
        
        # Time settings
        dnd-start|dnd-end)
            # Validate time format
            if ! [[ "$value" =~ ^([0-1][0-9]|2[0-3]):[0-5][0-9]$ ]]; then
                echo "Error: Time must be in 24-hour format (HH:MM)"
                exit 1
            fi
            
            case "$param" in
                dnd-start)
                    sed -i.bak '/DND_START_TIME=/d' "$CONFIG_FILE"
                    echo "DND_START_TIME=\"$value\"" >> "$CONFIG_FILE"
                    echo "Do Not Disturb start time set to $value"
                    ;;
                dnd-end)
                    sed -i.bak '/DND_END_TIME=/d' "$CONFIG_FILE"
                    echo "DND_END_TIME=\"$value\"" >> "$CONFIG_FILE"
                    echo "Do Not Disturb end time set to $value"
                    ;;
            esac
            ;;
        
        *)
            echo "Error: Unknown parameter '$param'"
            echo "Valid parameters:"
            echo "  Standard thresholds: cpu, gpu, wscpu, swap, fan, memory, streak"
            echo "  Alert management:    beeps, cooldown, severity"
            echo "  Boolean settings:    dnd (on/off), smart (on/off)"
            echo "  Time settings:       dnd-start (HH:MM), dnd-end (HH:MM)"
            exit 1
            ;;
    esac
    
    # Clean up backup file
    rm -f "${CONFIG_FILE}.bak"
}

# Function to reset thresholds to defaults
reset_thresholds() {
    if [ -f "$CONFIG_FILE" ]; then
        rm -f "$CONFIG_FILE"
        create_default_config
        echo "Reset all thresholds to default values"
    else
        create_default_config
        echo "Created default threshold configuration"
    fi
}

# Process command line arguments
case "$1" in
    list|show)
        show_thresholds
        ;;
    set)
        if [ $# -lt 3 ]; then
            echo "Usage: $(basename $0) set <parameter> <value>"
            echo "Parameters:"
            echo "  Standard thresholds: cpu, gpu, wscpu, swap, fan, memory, streak"
            echo "  Alert management:    beeps, cooldown, severity"
            echo "  Boolean settings:    dnd (on/off), smart (on/off)"
            echo "  Time settings:       dnd-start (HH:MM), dnd-end (HH:MM)"
            exit 1
        fi
        set_threshold "$2" "$3"
        ;;
    reset)
        reset_thresholds
        ;;
    *)
        echo "Usage: $(basename $0) {list|set|reset}"
        echo "  list              Show current threshold values"
        echo "  set PARAM VALUE   Set a specific threshold (see below)"
        echo "  reset             Reset all thresholds to defaults"
        echo ""
        echo "Available parameters:"
        echo "  Standard thresholds: cpu, gpu, wscpu, swap, fan, memory, streak"
        echo "  Alert management:    beeps, cooldown, severity"
        echo "  Boolean settings:    dnd (on/off), smart (on/off)"
        echo "  Time settings:       dnd-start (HH:MM), dnd-end (HH:MM)"
        echo ""
        echo "Examples:"
        echo "  $(basename $0) set cpu 85         # Set CPU temperature threshold to 85°C"
        echo "  $(basename $0) set beeps 1        # Set alert beep count to 1"
        echo "  $(basename $0) set dnd on         # Enable Do Not Disturb mode"
        echo "  $(basename $0) set dnd-start 22:00 # Set Do Not Disturb start time"
        exit 1
        ;;
esac

exit 0
