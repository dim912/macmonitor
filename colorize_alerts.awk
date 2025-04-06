#!/usr/bin/awk -f

# AWK script to add color to alert percentages in CLI display
# Takes pipe-delimited log data and adds color to the percentage values
# without modifying the original format
# This version uses standard AWK functions (no gensub)

BEGIN { 
    FS = "|"; 
    OFS = "|";
    
    # Color codes for different severity levels
    very_light_red = "\\033[38;5;174m";
    light_red = "\\033[38;5;168m";
    medium_red = "\\033[38;5;167m";
    bright_red = "\\033[38;5;196m";
    deep_red = "\\033[38;5;160m";
    reset = "\\033[0m";
}

{
    # Check if line has alerts with percentages
    if ($0 ~ /\+[0-9]+%/) {
        # Split alerts field for processing
        alerts = $9;
        result = "";
        
        # Process the alert field character by character
        in_number = 0;
        number = "";
        i = 1;
        
        while (i <= length(alerts)) {
            c = substr(alerts, i, 1);
            
            # Start of a percentage
            if (c == "+" && substr(alerts, i+1, 1) ~ /[0-9]/) {
                result = result "+";
                in_number = 1;
                number = "";
                i++;
                continue;
            }
            
            # Collecting the number
            if (in_number && c ~ /[0-9]/) {
                number = number c;
                i++;
                continue;
            }
            
            # End of a percentage
            if (in_number && c == "%") {
                # Apply color based on percentage value
                color = very_light_red;
                if (int(number) >= 5) color = light_red;
                if (int(number) >= 10) color = medium_red;
                if (int(number) >= 20) color = bright_red;
                if (int(number) >= 50) color = deep_red;
                
                result = result color number "%" reset;
                in_number = 0;
                i++;
                continue;
            }
            
            # Anything else
            if (in_number) {
                # Not a valid number anymore, add what we've collected
                result = result number;
                in_number = 0;
            }
            
            # Add the current character
            result = result c;
            i++;
        }
        
        # If we're still collecting a number at the end
        if (in_number) {
            result = result number;
        }
        
        # Replace the alerts field with our colored version
        $9 = result;
    }
    
    # Print the line (modified or not)
    print;
}
