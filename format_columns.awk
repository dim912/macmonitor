#!/usr/bin/awk -f

# MacMonitor column formatter
# - Fixes alignment issues between headers and data
# - Handles timestamp in either first or second column
# - Ensures consistent column widths
# - Always uses standard column headers

BEGIN {
    FS = "|";
    OFS = "|";
    
    # Define column headers
    col_names[1] = "Timestamp";
    col_names[2] = "CPU";
    col_names[3] = "GPU";
    col_names[4] = "WS CPU";
    col_names[5] = "Memory";
    col_names[6] = "Swap";
    col_names[7] = "Fan";
    col_names[8] = "Uptime";
    col_names[9] = "Alerts";
    
    # Set minimum widths
    min_width[1] = 20;  # Timestamp
    min_width[2] = 6;   # CPU
    min_width[3] = 6;   # GPU
    min_width[4] = 8;   # WS CPU
    min_width[5] = 9;   # Memory
    min_width[6] = 10;  # Swap
    min_width[7] = 8;   # Fan
    min_width[8] = 10;  # Uptime
    min_width[9] = 42;  # Alerts
    
    # Initialize widths
    for (i = 1; i <= 9; i++) {
        width[i] = min_width[i];
    }
    
    # Skip non-data lines
    row_count = 0;
}

# Process data rows with timestamp detection
{
    # Skip non-table and info lines
    if ($0 !~ /^\|/ || $0 ~ /Next refresh/) next;
    
    # Skip separator rows
    if ($0 ~ /^\|[-|]+$/) next;
    
    # Skip header rows from input
    if ($0 ~ /Timestamp.*CPU.*Memory/) next;
    
    # Look for a timestamp in the line
    has_timestamp = 0;
    timestamp_col = 0;
    
    for (i = 1; i <= NF; i++) {
        val = $i;
        gsub(/^[ \t]+|[ \t]+$/, "", val);
        
        if (val ~ /[0-9]{4}-[0-9]{2}-[0-9]{2}/) {
            has_timestamp = 1;
            timestamp_col = i;
            break;
        }
    }
    
    # Only process lines with a timestamp
    if (has_timestamp) {
        row_count++;
        
        if (timestamp_col == 2) {
            # Timestamp is in CPU column - need to fix
            
            # Extract the timestamp and put it in column 1
            ts_val = $timestamp_col;
            gsub(/^[ \t]+|[ \t]+$/, "", ts_val);
            row_data[row_count, 1] = ts_val;
            
            # Update width if needed
            if (length(ts_val) > width[1]) {
                width[1] = length(ts_val);
            }
            
            # Store remaining values shifted by one column left
            for (i = timestamp_col + 1; i <= NF; i++) {
                if ((i - timestamp_col + 1) > 9) continue;
                
                val = $i;
                gsub(/^[ \t]+|[ \t]+$/, "", val);
                
                col_idx = i - timestamp_col + 1;
                row_data[row_count, col_idx] = val;
                
                # Update width if needed
                if (length(val) > width[col_idx]) {
                    width[col_idx] = length(val);
                }
            }
        } else {
            # Normal row with timestamp in correct column
            
            for (i = 1; i <= NF; i++) {
                if (i > 9) continue;
                
                val = $i;
                gsub(/^[ \t]+|[ \t]+$/, "", val);
                
                row_data[row_count, i] = val;
                
                # Update width if needed
                if (length(val) > width[i]) {
                    width[i] = length(val);
                }
            }
        }
    }
}

END {
    # Check if we found any data rows
    if (row_count == 0) {
        print "No data rows with timestamps found.";
        exit 0;
    }
    
    # Ensure headers have enough width
    for (i = 1; i <= 9; i++) {
        if (length(col_names[i]) > width[i]) {
            width[i] = length(col_names[i]);
        }
    }
    
    # Print header row
    printf("|");
    for (i = 1; i <= 9; i++) {
        # Center header text
        padding = int((width[i] - length(col_names[i])) / 2);
        left_pad = "";
        right_pad = "";
        
        for (p = 0; p < padding; p++) left_pad = left_pad " ";
        for (p = 0; p < (width[i] - length(col_names[i]) - padding); p++) right_pad = right_pad " ";
        
        printf(" %s%s%s |", left_pad, col_names[i], right_pad);
    }
    printf("\n");
    
    # Print separator row
    printf("|");
    for (i = 1; i <= 9; i++) {
        for (j = 0; j < width[i] + 2; j++) printf("-");
        printf("|");
    }
    printf("\n");
    
    # Print data rows
    for (r = 1; r <= row_count; r++) {
        printf("|");
        for (i = 1; i <= 9; i++) {
            val = row_data[r, i] ? row_data[r, i] : "";
            
            if (i == 1 || i == 9) {
                # Left-align Timestamp and Alerts
                printf(" %-*s |", width[i], val);
            } else {
                # Center-align numeric columns
                padding = int((width[i] - length(val)) / 2);
                left_pad = "";
                right_pad = "";
                
                for (p = 0; p < padding; p++) left_pad = left_pad " ";
                for (p = 0; p < (width[i] - length(val) - padding); p++) right_pad = right_pad " ";
                
                printf(" %s%s%s |", left_pad, val, right_pad);
            }
        }
        printf("\n");
    }
}
