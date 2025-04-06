#!/usr/bin/awk -f

# AWK script to standardize column formats
# - Fixed column width issues
# - Standardizes uptime format
# - Handles headers and data rows in a consistent manner

BEGIN { 
    FS = "|"; 
    OFS = "|";
    
    # Define column headers and their positions
    col_names[1] = "Timestamp";
    col_names[2] = "CPU";
    col_names[3] = "GPU";
    col_names[4] = "WS CPU";
    col_names[5] = "Memory";
    col_names[6] = "Swap";
    col_names[7] = "Fan";
    col_names[8] = "Uptime";
    col_names[9] = "Alerts";
    
    # Set minimum widths for each column
    min_width[1] = 20;  # Timestamp (YYYY-MM-DD HH:MM:SS)
    min_width[2] = 6;   # CPU
    min_width[3] = 6;   # GPU
    min_width[4] = 8;   # WS CPU
    min_width[5] = 9;   # Memory
    min_width[6] = 10;  # Swap
    min_width[7] = 8;   # Fan
    min_width[8] = 10;  # Uptime
    min_width[9] = 42;  # Alerts - increased to accommodate alert messages
    
    # Initialize column widths to minimums
    for (i = 1; i <= 9; i++) {
        width[i] = min_width[i];
    }
    
    # Skip headers provided in input - we'll generate our own
    skip_lines = 2;
    line_num = 0;
    row_count = 0;
}

# Skip header lines from the input
{
    line_num++;
    if (line_num <= skip_lines) next;
}

# Process data lines only
$0 ~ /\|[ ]*[0-9]{4}-[0-9]{2}-[0-9]{2}[ ][0-9]{2}:[0-9]{2}:[0-9]{2}[ ]*\|/ {
    row_count++;
    
    # Extract and clean fields - skip the empty first field
    for (i = 2; i <= NF; i++) {
        if (i > 10) continue; # Skip any extra fields
        
        # Get index in our data array (subtract 1 because input has an empty column)
        idx = i-1;
        if (idx < 1 || idx > 9) continue;
        
        # Clean up the field value
        val = $i;
        gsub(/^[ \t]+|[ \t]+$/, "", val);
        data[row_count, idx] = val;
        
        # Update column width if this value is wider
        if (length(val) > width[idx]) {
            width[idx] = length(val);
        }
    }
    
    # Standardize uptime format in column 8
    if (data[row_count, 8] ~ /hrs?$/ || data[row_count, 8] ~ /hours?$/) {
        hour = data[row_count, 8];
        gsub(/[^0-9].*$/, "", hour);
        data[row_count, 8] = hour ":00";
    }
}

END {
    # Check if headers need additional width
    for (i = 1; i <= 9; i++) {
        if (length(col_names[i]) > width[i]) {
            width[i] = length(col_names[i]);
        }
    }
    
    # Print header row
    printf("| ");
    for (i = 1; i <= 9; i++) {
        name = col_names[i];
        
        # Center the header text
        padding = int((width[i] - length(name)) / 2);
        left_pad = "";
        right_pad = "";
        
        for (p = 0; p < padding; p++) left_pad = left_pad " ";
        for (p = 0; p < (width[i] - length(name) - padding); p++) right_pad = right_pad " ";
        
        printf("%s%s%s | ", left_pad, name, right_pad);
    }
    printf("\n");
    
    # Print separator row
    printf("|");
    for (i = 1; i <= 9; i++) {
        printf("-");
        for (j = 0; j < width[i]; j++) printf("-");
        printf("-|");
    }
    printf("\n");
    
    # Print data rows
    for (r = 1; r <= row_count; r++) {
        printf("| ");
        for (i = 1; i <= 9; i++) {
            val = data[r, i] ? data[r, i] : "";
            
            if (i == 1 || i == 9) {
                # Left-align Timestamp and Alerts
                printf("%-*s | ", width[i], val);
            } else {
                # Center-align numeric columns
                padding = int((width[i] - length(val)) / 2);
                left_pad = "";
                right_pad = "";
                
                for (p = 0; p < padding; p++) left_pad = left_pad " ";
                for (p = 0; p < (width[i] - length(val) - padding); p++) right_pad = right_pad " ";
                
                printf("%s%s%s | ", left_pad, val, right_pad);
            }
        }
        printf("\n");
    }
}
