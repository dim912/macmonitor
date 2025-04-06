#!/bin/bash
#
# Mac System Monitor
# A lightweight monitoring script that logs system metrics and provides alerts.
#
# This script runs as a LaunchAgent service and logs:
# - CPU and GPU temperatures
# - Fan speeds
# - WindowServer CPU usage
# - Memory pressure
# - Swap usage
# - System uptime

#----------------------------------------
# SETUP AND CONFIGURATION
#----------------------------------------

# Set PATH to include common locations for executables
# LaunchAgents don't inherit the user's PATH, so we need to set it explicitly
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/usr/local/sbin:/opt/homebrew/sbin:$PATH"

# Define home directory explicitly as LaunchAgents may not expand ~ properly
HOME_DIR="$HOME"
if [ -z "$HOME_DIR" ]; then
    # Fallback if HOME isn't set
    HOME_DIR=$(eval echo ~$(whoami))
fi

# Setup log directories and configuration
LOG_DIR="$HOME_DIR/monitor_logs"
ALERT_DIR="$LOG_DIR/alerts"
mkdir -p "$LOG_DIR" "$ALERT_DIR"
INTERVAL=30  # Seconds between monitoring checks
LOW_MEM_STREAK=0  # Counter for consecutive low memory detections

# Alert thresholds - Default values (can be overridden by thresholds.conf)
CPU_TEMP_THRESHOLD=85
GPU_TEMP_THRESHOLD=85
WS_CPU_THRESHOLD=50
SWAP_THRESHOLD=500
FAN_SPEED_THRESHOLD=5000
MEMORY_THRESHOLD=90
LOW_MEM_STREAK_THRESHOLD=3

# Alert management settings
BEEP_COUNT=2                       # Number of beeps per alert (reduced from 10)
ALERT_COOLDOWN=10                  # Minutes between alerts of same type
ALERT_SEVERITY_THRESHOLD=2         # Minimum severity level to show alerts (1=low, 2=medium, 3=high)
DND_MODE=false                     # Do Not Disturb mode
DND_START_TIME="23:00"             # Start of Do Not Disturb window
DND_END_TIME="07:00"               # End of Do Not Disturb window
SMART_THRESHOLD_ENABLED=true       # Use adaptive thresholds based on system behavior

# Alert tracking
declare -A LAST_ALERT_TIME         # Associative array to track last alert time by type
declare -A ALERT_SNOOZE_UNTIL      # Track snoozed alerts until timestamp
declare -A PREV_VALUES             # Store previous values to calculate trends
declare -A THRESHOLD_ADJUSTMENTS   # Store dynamic threshold adjustments

# Load custom thresholds if they exist
CONFIG_DIR="$HOME_DIR/.monitor"
CONFIG_FILE="$CONFIG_DIR/thresholds.conf"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    echo "$(date) - Loaded custom thresholds from $CONFIG_FILE" >> "$LOG_DIR/monitor_startup.log"
else
    echo "$(date) - Using default thresholds" >> "$LOG_DIR/monitor_startup.log"
fi

# Find paths for required tools (allows for different install locations)
BREW_PATH=$(which brew 2>/dev/null || echo "")
OSX_CPU_TEMP_PATH=$(which osx-cpu-temp 2>/dev/null || echo "")
ISTATS_PATH=$(which istats 2>/dev/null || echo "")
POWERMETRICS_PATH=$(which powermetrics 2>/dev/null || echo "/usr/bin/powermetrics")

# Create startup log for troubleshooting
echo "$(date) - Monitor starting with:" > "$LOG_DIR/monitor_startup.log"
echo "PATH: $PATH" >> "$LOG_DIR/monitor_startup.log"
echo "Brew path: $BREW_PATH" >> "$LOG_DIR/monitor_startup.log"
echo "osx-cpu-temp path: $OSX_CPU_TEMP_PATH" >> "$LOG_DIR/monitor_startup.log"
echo "istats path: $ISTATS_PATH" >> "$LOG_DIR/monitor_startup.log"
echo "powermetrics path: $POWERMETRICS_PATH" >> "$LOG_DIR/monitor_startup.log"

#----------------------------------------
# HELPER FUNCTIONS
#----------------------------------------

# macOS native notification function
notify() {
    osascript -e "display notification \"$1\" with title \"System Monitor Alert\""
}

#----------------------------------------
# MAIN MONITORING LOOP
#----------------------------------------

while true
do
    # Setup log files for today and clean old logs
    LOG_FILE="$LOG_DIR/dual_monitor_log_$(date +%Y-%m-%d).txt"
    ALERT_FILE="$ALERT_DIR/memory_alerts_$(date +%Y-%m-%d).log"
    find "$LOG_DIR" -type f -name "*.txt" -mtime +2 -delete  # Delete logs older than 2 days
    find "$ALERT_DIR" -type f -name "*.log" -mtime +2 -delete
    TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
    
    #------------------------
    # COLLECT SYSTEM METRICS
    #------------------------
    
    # 1. CPU Temperature - try osx-cpu-temp first, fallback to system_profiler
    if [ -n "$OSX_CPU_TEMP_PATH" ]; then
        CPU_TEMP=$("$OSX_CPU_TEMP_PATH" 2>/dev/null || echo "N/A")
    else
        CPU_TEMP=$(system_profiler SPPowerDataType 2>/dev/null | grep -i "CPU die temperature" | awk -F ':' '{print $2}' | xargs || echo "N/A")
    fi
    
    # 2. GPU Temperature - try multiple methods
    GPU_TEMP="N/A"
    # Method 1: Try passwordless sudo first (configured by setup_gpu_permissions.sh)
    if [ -n "$POWERMETRICS_PATH" ]; then
        GPU_TEMP=$(sudo -n "$POWERMETRICS_PATH" --samplers smc -n1 2>/dev/null | grep -i "GPU die temperature" | awk -F ':' '{print $2}' | xargs)
        # If passwordless sudo fails, try without sudo (usually fails but try anyway)
        if [ -z "$GPU_TEMP" ]; then
            GPU_TEMP=$("$POWERMETRICS_PATH" --samplers smc -n1 2>/dev/null | grep -i "GPU die temperature" | awk -F ':' '{print $2}' | xargs)
        fi
    fi
    
    # Method 2: Try system_profiler as fallback
    if [ -z "$GPU_TEMP" ] || [ "$GPU_TEMP" == "N/A" ]; then
        GPU_TEMP=$(system_profiler SPDisplaysDataType 2>/dev/null | grep -i "Temperature" | head -n1 | awk -F ':' '{print $2}' | xargs || echo "N/A")
    fi
    [[ -z "$GPU_TEMP" ]] && GPU_TEMP="N/A"
    
    # 3. Other system metrics
    WINDOWSERVER_USAGE=$(ps -A -o %cpu,command | grep -i "WindowServer" | awk '{sum += $1} END {print sum}')
    SWAP_USED=$(/usr/sbin/sysctl vm.swapusage | awk '{print $7}')
    
    # 4. Fan Speed - try iStats first, fallback to smcFanControl
    if [ -n "$ISTATS_PATH" ]; then
        FAN_SPEED=$("$ISTATS_PATH" fan speed 2>/dev/null | grep "Fan 0" | awk -F ':' '{print $2}' | xargs || echo "N/A")
        [[ -z "$FAN_SPEED" ]] && FAN_SPEED="N/A"
    else
        if [ -f "/usr/local/bin/smcFanControl" ]; then
            FAN_SPEED=$("/usr/local/bin/smcFanControl" -r 2>/dev/null | grep "Current speed" | awk '{print $3}' || echo "N/A")
        else
            FAN_SPEED="N/A"
        fi
    fi
    
    # 5. System uptime
    UPTIME=$(uptime | awk -F 'up ' '{print $2}' | awk -F ',' '{print $1}')
    
    # 6. Memory pressure - try memory_pressure command, fallback to vm_stat
    MEM_PRESSURE_RAW=$(memory_pressure 2>/dev/null | grep "System-wide memory free" | awk '{print $NF}' || echo "")
    if [[ -z "$MEM_PRESSURE_RAW" ]]; then
        MEM_USED_PCT=$(vm_stat | grep "Pages active" | awk '{print $3}' | sed 's/\.//')
        MEM_PRESSURE_LEVEL="${MEM_USED_PCT:-Unknown}%"
    else
        MEM_PRESSURE_LEVEL="$MEM_PRESSURE_RAW"
    fi

    #------------------------
    # PROCESS METRICS
    #------------------------
    
    # Convert values to integers where possible
    if [[ "$CPU_TEMP" != "N/A" ]]; then
        CPU_TEMP_VAL=$(echo "$CPU_TEMP" | awk '{print int($1)}')
    else
        CPU_TEMP_VAL="N/A"
    fi
    
    if [[ "$GPU_TEMP" != "N/A" ]]; then
        GPU_TEMP_VAL=$(echo "$GPU_TEMP" | awk '{print int($1)}')
    else
        GPU_TEMP_VAL="N/A"
    fi
    
    WS_CPU=$(printf "%.0f" "${WINDOWSERVER_USAGE:-0}")
    SWAP_MB=$(echo "$SWAP_USED" | sed 's/M//;s/G/000/')
    
    if [[ "$FAN_SPEED" != "N/A" ]]; then
        FAN_RPM=$(echo "$FAN_SPEED" | awk '{print int($1)}')
    else
        FAN_RPM="N/A"
    fi

    #------------------------
    # ALERT DETECTION
    #------------------------
    
    # Function to determine if we're in Do Not Disturb hours
    in_dnd_period() {
        if [ "$DND_MODE" = false ]; then
            return 1  # Not in DND if feature is disabled
        fi
        
        current_hour=$(date +"%H:%M")
        dnd_start=$(echo "$DND_START_TIME" | sed 's/://g')
        dnd_end=$(echo "$DND_END_TIME" | sed 's/://g')
        current=$(echo "$current_hour" | sed 's/://g')
        
        # Handle overnight DND period (e.g., 23:00-07:00)
        if [ "$dnd_start" -gt "$dnd_end" ]; then
            if [ "$current" -ge "$dnd_start" ] || [ "$current" -lt "$dnd_end" ]; then
                return 0  # In DND period
            fi
        else
            # Normal DND period (e.g., 09:00-17:00)
            if [ "$current" -ge "$dnd_start" ] && [ "$current" -lt "$dnd_end" ]; then
                return 0  # In DND period
            fi
        fi
        
        return 1  # Not in DND period
    }
    
    # Function to check if an alert type is in cooldown
    is_in_cooldown() {
        local alert_type="$1"
        local now=$(date +%s)
        
        # Check if we have a record for this alert type
        if [ -n "${LAST_ALERT_TIME[$alert_type]}" ]; then
            local cooldown_ends=$((${LAST_ALERT_TIME[$alert_type]} + ALERT_COOLDOWN * 60))
            if [ $now -lt $cooldown_ends ]; then
                return 0  # Still in cooldown
            fi
        fi
        
        # Update the last alert time for this type
        LAST_ALERT_TIME[$alert_type]=$now
        return 1  # Not in cooldown
    }
    
    # Function to check if an alert is snoozed
    is_snoozed() {
        local alert_type="$1"
        local now=$(date +%s)
        
        # Check if alert is snoozed
        if [ -n "${ALERT_SNOOZE_UNTIL[$alert_type]}" ]; then
            if [ $now -lt ${ALERT_SNOOZE_UNTIL[$alert_type]} ]; then
                return 0  # Alert is snoozed
            else
                # Snooze period is over, clear the snooze
                unset ALERT_SNOOZE_UNTIL[$alert_type]
            fi
        fi
        
        return 1  # Not snoozed
    }
    
    # Adjust thresholds based on system behavior if smart thresholds are enabled
    if [ "$SMART_THRESHOLD_ENABLED" = true ]; then
        # Store current values for future trend analysis
        if [[ "$CPU_TEMP_VAL" != "N/A" ]]; then PREV_VALUES[cpu]=$CPU_TEMP_VAL; fi
        if [[ "$GPU_TEMP_VAL" != "N/A" ]]; then PREV_VALUES[gpu]=$GPU_TEMP_VAL; fi
        if [[ "$WS_CPU" != "N/A" ]]; then PREV_VALUES[wscpu]=$WS_CPU; fi
        if [[ "$SWAP_MB" != "N/A" ]]; then PREV_VALUES[swap]=$SWAP_MB; fi
        if [[ "$FAN_RPM" != "N/A" ]]; then PREV_VALUES[fan]=$FAN_RPM; fi
        
        # Adjust thresholds based on trends (simplified implementation)
        # For a more sophisticated approach, you'd analyze values over a longer period
    fi
    
    ALERT=""
    TRIGGER_BEEP=false
    ALL_ALERTS=""
    ALERT_COUNT=0
    HIGHEST_SEVERITY=0
    
    # Check thresholds for various metrics with detailed alerts
    if [[ "$CPU_TEMP_VAL" != "N/A" && "$CPU_TEMP_VAL" -gt $CPU_TEMP_THRESHOLD ]]; then
        # Calculate percentage over threshold
        CPU_DRIFT=$(( (CPU_TEMP_VAL - CPU_TEMP_THRESHOLD) * 100 / CPU_TEMP_THRESHOLD ))
        
        # Determine severity (1=low, 2=medium, 3=high)
        CPU_SEVERITY=1
        if [ $CPU_DRIFT -gt 20 ]; then CPU_SEVERITY=2; fi
        if [ $CPU_DRIFT -gt 40 ]; then CPU_SEVERITY=3; fi
        
        # Only add to alert if we pass cooldown and severity checks
        if ! is_in_cooldown "cpu" && ! is_snoozed "cpu" && [ $CPU_SEVERITY -ge $ALERT_SEVERITY_THRESHOLD ]; then
            ALERT+=" [CPU ${CPU_TEMP_VAL}/${CPU_TEMP_THRESHOLD}°C +${CPU_DRIFT}%]"
            ALL_ALERTS+="CPU: ${CPU_TEMP_VAL}°C (+${CPU_DRIFT}%)\n"
            ((ALERT_COUNT++))
            # Update highest severity if needed
            if [ $CPU_SEVERITY -gt $HIGHEST_SEVERITY ]; then
                HIGHEST_SEVERITY=$CPU_SEVERITY
            fi
        fi
    fi
    
    if [[ "$GPU_TEMP_VAL" != "N/A" && "$GPU_TEMP_VAL" -gt $GPU_TEMP_THRESHOLD ]]; then
        # Calculate percentage over threshold
        GPU_DRIFT=$(( (GPU_TEMP_VAL - GPU_TEMP_THRESHOLD) * 100 / GPU_TEMP_THRESHOLD ))
        
        # Determine severity
        GPU_SEVERITY=1
        if [ $GPU_DRIFT -gt 20 ]; then GPU_SEVERITY=2; fi
        if [ $GPU_DRIFT -gt 40 ]; then GPU_SEVERITY=3; fi
        
        if ! is_in_cooldown "gpu" && ! is_snoozed "gpu" && [ $GPU_SEVERITY -ge $ALERT_SEVERITY_THRESHOLD ]; then
            ALERT+=" [GPU ${GPU_TEMP_VAL}/${GPU_TEMP_THRESHOLD}°C +${GPU_DRIFT}%]"
            ALL_ALERTS+="GPU: ${GPU_TEMP_VAL}°C (+${GPU_DRIFT}%)\n"
            ((ALERT_COUNT++))
            if [ $GPU_SEVERITY -gt $HIGHEST_SEVERITY ]; then
                HIGHEST_SEVERITY=$GPU_SEVERITY
            fi
        fi
    fi
    
    if [[ "$WS_CPU" -gt $WS_CPU_THRESHOLD ]]; then
        # Calculate percentage over threshold
        WS_DRIFT=$(( (WS_CPU - WS_CPU_THRESHOLD) * 100 / WS_CPU_THRESHOLD ))
        
        # Determine severity
        WS_SEVERITY=1
        if [ $WS_DRIFT -gt 50 ]; then WS_SEVERITY=2; fi
        if [ $WS_DRIFT -gt 100 ]; then WS_SEVERITY=3; fi
        
        if ! is_in_cooldown "wscpu" && ! is_snoozed "wscpu" && [ $WS_SEVERITY -ge $ALERT_SEVERITY_THRESHOLD ]; then
            ALERT+=" [WS CPU ${WS_CPU}/${WS_CPU_THRESHOLD}% +${WS_DRIFT}%]"
            ALL_ALERTS+="WindowServer CPU: ${WS_CPU}% (+${WS_DRIFT}%)\n"
            ((ALERT_COUNT++))
            if [ $WS_SEVERITY -gt $HIGHEST_SEVERITY ]; then
                HIGHEST_SEVERITY=$WS_SEVERITY
            fi
        fi
    fi
    
    if [[ "$SWAP_MB" != "N/A" ]] && (( $(echo "$SWAP_MB > $SWAP_THRESHOLD" | bc -l) )); then
        # For swap, handle decimal values
        SWAP_VAL=$(echo "$SWAP_MB" | sed 's/M//')
        SWAP_DRIFT=$(echo "scale=0; ($SWAP_VAL - $SWAP_THRESHOLD) * 100 / $SWAP_THRESHOLD" | bc)
        
        # Determine severity
        SWAP_SEVERITY=1
        if [ "$SWAP_DRIFT" -gt 100 ]; then SWAP_SEVERITY=2; fi
        if [ "$SWAP_DRIFT" -gt 500 ]; then SWAP_SEVERITY=3; fi
        
        if ! is_in_cooldown "swap" && ! is_snoozed "swap" && [ $SWAP_SEVERITY -ge $ALERT_SEVERITY_THRESHOLD ]; then
            ALERT+=" [SWAP ${SWAP_USED}/${SWAP_THRESHOLD}MB +${SWAP_DRIFT}%]"
            ALL_ALERTS+="Swap usage: ${SWAP_USED} (+${SWAP_DRIFT}%)\n"
            ((ALERT_COUNT++))
            if [ $SWAP_SEVERITY -gt $HIGHEST_SEVERITY ]; then
                HIGHEST_SEVERITY=$SWAP_SEVERITY
            fi
        fi
    fi
    
    if [[ "$FAN_RPM" != "N/A" && "$FAN_RPM" -gt $FAN_SPEED_THRESHOLD ]]; then
        # Calculate percentage over threshold
        FAN_DRIFT=$(( (FAN_RPM - FAN_SPEED_THRESHOLD) * 100 / FAN_SPEED_THRESHOLD ))
        
        # Determine severity
        FAN_SEVERITY=1
        if [ $FAN_DRIFT -gt 25 ]; then FAN_SEVERITY=2; fi
        if [ $FAN_DRIFT -gt 100 ]; then FAN_SEVERITY=3; fi
        
        if ! is_in_cooldown "fan" && ! is_snoozed "fan" && [ $FAN_SEVERITY -ge $ALERT_SEVERITY_THRESHOLD ]; then
            ALERT+=" [FAN ${FAN_RPM}/${FAN_SPEED_THRESHOLD} +${FAN_DRIFT}%]"
            ALL_ALERTS+="Fan speed: ${FAN_RPM} RPM (+${FAN_DRIFT}%)\n"
            ((ALERT_COUNT++))
            if [ $FAN_SEVERITY -gt $HIGHEST_SEVERITY ]; then
                HIGHEST_SEVERITY=$FAN_SEVERITY
            fi
        fi
    fi

    # Memory pressure tracking
    MEM_VAL=$(echo "$MEM_PRESSURE_LEVEL" | sed 's/%//')
    if [[ "$MEM_PRESSURE_LEVEL" == "Warning" || "$MEM_PRESSURE_LEVEL" == "Critical" || "$MEM_VAL" -gt $MEMORY_THRESHOLD ]]; then
        ((LOW_MEM_STREAK++))
        
        # Only show memory alert after consecutive cycles
        if [[ $LOW_MEM_STREAK -ge $LOW_MEM_STREAK_THRESHOLD ]]; then
            # Determine severity
            MEM_SEVERITY=2  # Default to medium
            if [[ "$MEM_PRESSURE_LEVEL" == "Critical" ]]; then 
                MEM_SEVERITY=3
            elif [[ "$MEM_VAL" -gt $((MEMORY_THRESHOLD + 10)) ]]; then
                MEM_SEVERITY=3
            fi
            
            if ! is_in_cooldown "memory" && ! is_snoozed "memory" && [ $MEM_SEVERITY -ge $ALERT_SEVERITY_THRESHOLD ]; then
                if [[ "$MEM_PRESSURE_LEVEL" == "Warning" || "$MEM_PRESSURE_LEVEL" == "Critical" ]]; then
                    ALERT+=" [MEM ${MEM_PRESSURE_LEVEL}/${MEMORY_THRESHOLD}%]"
                    ALL_ALERTS+="Memory: ${MEM_PRESSURE_LEVEL}\n"
                else
                    MEM_DRIFT=$(( (MEM_VAL - MEMORY_THRESHOLD) * 100 / MEMORY_THRESHOLD ))
                    ALERT+=" [MEM ${MEM_VAL}/${MEMORY_THRESHOLD}% +${MEM_DRIFT}%]"
                    ALL_ALERTS+="Memory: ${MEM_VAL}% (+${MEM_DRIFT}%)\n"
                fi
                ((ALERT_COUNT++))
                if [ $MEM_SEVERITY -gt $HIGHEST_SEVERITY ]; then
                    HIGHEST_SEVERITY=$MEM_SEVERITY
                fi
            fi
            
            # Log memory alerts regardless of notification status
            echo "[$TIMESTAMP] LOW MEMORY ALERT (level: $MEM_PRESSURE_LEVEL)" >> "$ALERT_FILE"
            echo "Top memory apps:" >> "$ALERT_FILE"
            ps -axo pid,comm,%mem,rss | sort -k4 -n -r | head -n 10 >> "$ALERT_FILE"
            echo "-------------------------------------------" >> "$ALERT_FILE"
        fi
    else
        LOW_MEM_STREAK=0
    fi

    # Send alerts if thresholds exceeded, cooldown passed, and not in DND mode
    if [ -n "$ALERT" ] && ! in_dnd_period; then
        # Set prefix based on severity
        PREFIX="⚠️"
        if [ $HIGHEST_SEVERITY -eq 3 ]; then
            PREFIX="🔴"  # Red circle for high severity
        elif [ $HIGHEST_SEVERITY -eq 2 ]; then
            PREFIX="🟠"  # Orange circle for medium severity
        fi
        
        # Create an aggregated alert notification
        if [ $ALERT_COUNT -gt 1 ]; then
            NOTIFICATION="${PREFIX} ${ALERT_COUNT} system alerts detected"
            if [ $HIGHEST_SEVERITY -eq 3 ]; then
                NOTIFICATION+=" (CRITICAL)"
            fi
            NOTIFICATION+="\n${ALL_ALERTS}"
        else
            NOTIFICATION="${PREFIX} Alert: ${ALL_ALERTS}"
        fi
        
        # Send the notification
        notify "$NOTIFICATION"
        
        # Play fewer beeps
        for ((i=1; i<=BEEP_COUNT; i++)); do
            printf '\a'  # System beep
            sleep 0.5
        done
        
        TRIGGER_BEEP=true
    fi

    #------------------------
    # LOGGING
    #------------------------
    
    # Create header if this is a new log file
    if [ ! -f "$LOG_FILE" ]; then
        echo "Monitoring started at $(date)" >> "$LOG_FILE"
        echo "------------------------------------------------------------------------------------------------------------------------------------" >> "$LOG_FILE"
        echo "|      Time       | CPU°C | GPU°C | WS CPU% | Mem Status | Swap Used | Fan RPM | Uptime         | Alerts           |" >> "$LOG_FILE"
        echo "------------------------------------------------------------------------------------------------------------------------------------" >> "$LOG_FILE"
    fi

    # Write monitoring data to log file
    printf "| %-16s | %-6s | %-6s | %-7s | %-11s | %-9s | %-8s | %-14s | %-16s |\n" \
        "$TIMESTAMP" "$CPU_TEMP_VAL" "$GPU_TEMP_VAL" "$WS_CPU" "$MEM_PRESSURE_LEVEL" "$SWAP_USED" "$FAN_RPM" "$UPTIME" "$ALERT" >> "$LOG_FILE"

    # Wait for next monitoring cycle
    sleep $INTERVAL
done
