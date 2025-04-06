class Macmonitor < Formula
  desc "Lightweight macOS system monitoring tool with customizable alerts"
  homepage "https://github.com/dim912/macmonitor"
  url "https://github.com/dim912/macmonitor/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "PLACEHOLDER_SHA256_HASH" # Replace with actual hash after creating the release
  version "1.0.0"
  license "MIT"

  depends_on "osx-cpu-temp"
  depends_on "watch" # For monitoring display
  depends_on "gawk" # For AWK scripts
  
  def install
    # Install main script
    bin.install "mm"
    
    # Install supporting scripts and config files
    prefix.install "colorize_alerts.awk"
    prefix.install "format_columns.awk"
    prefix.install "config_thresholds.sh"
    prefix.install "monitor_status.sh"
    
    # Install documentation
    doc.install "README.md"
    doc.install "USAGE_GUIDE.md"
    doc.install "ADVANCED_USAGE.md"
    
    # Create deployment scripts directory
    (prefix/"deploy").mkpath
    (prefix/"deploy").install Dir["website/s3/*"]
    
    # Set up credentials template
    (prefix/"templates").mkpath
    (prefix/"templates").install "com.user.monitorlogger.plist.template"
    
    # Create a wrapper script that sets the correct paths
    (bin/"macmonitor").write <<~EOS
      #!/bin/bash
      INSTALL_DIR="#{prefix}"
      exec "#{bin}/mm" --config-dir="$INSTALL_DIR" "$@"
    EOS
    chmod 0755, bin/"macmonitor"
  end

  def post_install
    # Attempt to create log directory with proper permissions
    system "mkdir", "-p", "/var/log/macmonitor"
    system "chmod", "755", "/var/log/macmonitor"
    
    # Display installation message
    ohai "MacMonitor Installation Complete"
    ohai "To start monitoring, run: macmonitor"
  end

  def caveats
    <<~EOS
      MacMonitor has been installed!
      
      Quick Start:
        macmonitor            # Run the monitor with default settings
        macmonitor --help     # Show all available options
      
      Configuration files are located at:
        #{prefix}
      
      To set up automatic monitoring on startup:
        sudo cp #{prefix}/templates/com.user.monitorlogger.plist.template /Library/LaunchDaemons/com.user.macmonitor.plist
        # Edit the plist file to set correct paths
        sudo launchctl load /Library/LaunchDaemons/com.user.macmonitor.plist
      
      Log files will be stored at:
        /var/log/macmonitor/
      
      Deployment scripts for the website are available at:
        #{prefix}/deploy/
    EOS
  end

  test do
    # Basic test to ensure the script runs without errors
    assert_match "MacMonitor v#{version}", shell_output("#{bin}/macmonitor --version")
  end
end
