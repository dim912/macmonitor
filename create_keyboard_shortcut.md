# Setting Up a Keyboard Shortcut for Mac System Monitor Dashboard

You can set up a keyboard shortcut to quickly refresh and view your Mac System Monitor dashboard. This guide will walk you through creating a macOS Quick Action (formerly known as a Service) that can be triggered with a keyboard shortcut.

## Creating a Quick Action in Automator

1. **Open Automator**:
   - Open Automator from your Applications folder
   - Choose "Quick Action" as the document type

2. **Configure the Quick Action**:
   - In the top panel, set:
     - "Workflow receives current: No input"
     - "in: any application"
   
3. **Add a Run Shell Script action**:
   - Search for "Run Shell Script" in the actions library
   - Drag it to the workflow area
   - Set "Shell" to `/bin/bash`
   - Set "Pass input" to "as arguments"
   - Enter the following script:

   ```bash
   # For Homebrew installation
   if command -v mm &> /dev/null; then
       mm update
   # For manual installation
   else
       if [ -f "$HOME/AIScripts/MacMonitor/generate_dashboard_data.sh" ]; then
           $HOME/AIScripts/MacMonitor/generate_dashboard_data.sh
       else
           # Try to find the script in common locations
           SCRIPT_PATH=$(find $HOME -name "generate_dashboard_data.sh" -maxdepth 3 2>/dev/null | head -n 1)
           if [ -n "$SCRIPT_PATH" ]; then
               $SCRIPT_PATH
           else
               osascript -e 'display notification "Could not find Mac Monitor dashboard script" with title "Mac Monitor"'
           fi
       fi
   fi
   ```

4. **Save the Quick Action**:
   - Click File > Save
   - Name it "Refresh Mac Monitor Dashboard"
   - Click Save

## Assigning a Keyboard Shortcut

1. **Open System Preferences**:
   - Go to System Preferences > Keyboard > Shortcuts

2. **Select Services**:
   - In the left panel, select "Services"
   - Scroll down to "General" section
   - Find "Refresh Mac Monitor Dashboard"

3. **Assign a Shortcut**:
   - Click where it says "none" next to the service
   - Press your desired keyboard shortcut, for example: `⌃⌥⌘M` (Control+Option+Command+M)
   - Close System Preferences

## Using the Shortcut

Now you can press your assigned keyboard shortcut from any application to refresh and open the Mac System Monitor dashboard.

## For Touch Bar Macs

If your Mac has a Touch Bar, you can add this action to it:

1. Go to System Preferences > Keyboard > Customize Control Strip
2. Drag the "Quick Actions" item to your Touch Bar
3. Now when you tap this button, you'll see your "Refresh Mac Monitor Dashboard" action
