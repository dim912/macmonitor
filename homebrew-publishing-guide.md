# Publishing MacMonitor as a Homebrew Package

This guide explains how to properly package and publish MacMonitor as a Homebrew formula, making it easy for users to install with a simple `brew install` command.

## Overview of the Process

1. Create a GitHub release with packaged source code
2. Update the Homebrew formula with correct URL and SHA256
3. Create a Homebrew tap repository
4. Test the formula locally
5. Publish the tap
6. (Optional) Submit to Homebrew core for wider distribution

## Step 1: Create a GitHub Release

1. Ensure your repository is public on GitHub
2. Clean up the codebase and ensure all files are properly organized
3. Create a tar.gz archive of your project:

```bash
# From the project root directory
git archive --format=tar.gz --prefix=macmonitor-1.0.0/ -o macmonitor-1.0.0.tar.gz HEAD
```

4. Create a new release on GitHub:
   - Go to your repository on GitHub
   - Click on "Releases" then "Create a new release"
   - Set the tag version (e.g., `v1.0.0`)
   - Upload the `macmonitor-1.0.0.tar.gz` file
   - Publish the release

5. Note the URL to the tar.gz file, which will be something like:
   `https://github.com/username/macmonitor/archive/refs/tags/v1.0.0.tar.gz`

6. Calculate the SHA256 hash of the tar.gz file:

```bash
shasum -a 256 macmonitor-1.0.0.tar.gz
```

## Step 2: Update the Homebrew Formula

Update the `macmonitor.rb` formula with the correct information:

```ruby
class Macmonitor < Formula
  desc "Lightweight macOS system monitoring tool that logs system metrics and provides alerts"
  homepage "https://github.com/username/macmonitor"
  url "https://github.com/username/macmonitor/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "the-actual-sha256-hash-from-step-1"
  version "1.0.0"
  license "MIT"

  depends_on "osx-cpu-temp"
  depends_on "watch" # For mm cli command
  
  def install
    bin.install "mm"
    # Install other necessary files
    prefix.install "config_thresholds.sh"
    prefix.install "colorize_alerts.awk"
    prefix.install "format_columns.awk"
    # Install documentation
    doc.install "README.md", "USAGE_GUIDE.md"
    # Create a wrapper script that sets the correct paths
    (bin/"macmonitor").write <<~EOS
      #!/bin/bash
      INSTALL_DIR="#{prefix}"
      exec "#{bin}/mm" --config-dir="$INSTALL_DIR" "$@"
    EOS
    chmod 0755, bin/"macmonitor"
  end

  def caveats
    <<~EOS
      MacMonitor has been installed.
      
      Run it with:
        macmonitor
      
      Or use the original script:
        mm
      
      Configuration files are located at:
        #{prefix}
    EOS
  end

  test do
    system "#{bin}/mm", "--help"
  end
end
```

Note: Adjust the `install` method based on which files need to be included in the installation.

## Step 3: Create a Homebrew Tap Repository

A tap is a GitHub repository that contains Homebrew formulas.

1. Create a new GitHub repository named `homebrew-tap` (the `homebrew-` prefix is important)

2. Clone the repository:

```bash
git clone https://github.com/username/homebrew-tap.git
cd homebrew-tap
```

3. Create a `Formula` directory and add your updated `macmonitor.rb` formula:

```bash
mkdir -p Formula
cp /path/to/macmonitor.rb Formula/
```

4. Commit and push to GitHub:

```bash
git add Formula/macmonitor.rb
git commit -m "Add MacMonitor formula"
git push
```

## Step 4: Test the Formula Locally

Before publishing, test that the formula works properly:

```bash
# Add your tap
brew tap username/tap https://github.com/username/homebrew-tap.git

# Install from your tap
brew install username/tap/macmonitor

# Or install locally for testing
brew install --build-from-source /path/to/Formula/macmonitor.rb
```

Fix any issues that arise during testing.

## Step 5: Publish the Tap

Once testing is complete, your tap is already published! Users can install MacMonitor with:

```bash
brew tap username/tap
brew install macmonitor
```

Or in one command:

```bash
brew install username/tap/macmonitor
```

## Step 6: (Optional) Submit to Homebrew Core

To make your formula available without requiring users to add your tap:

1. Fork the Homebrew core repository: https://github.com/Homebrew/homebrew-core
2. Add your formula to the forked repository
3. Submit a pull request
4. Address any feedback from Homebrew maintainers

Note that Homebrew core has strict requirements for acceptance, including:
- The formula must be actively maintained
- It should have wide appeal to macOS users
- It should meet Homebrew's quality guidelines

## Updating the Formula

When you release a new version:

1. Create a new GitHub release with the updated version
2. Update the formula with the new URL, SHA256, and version
3. Push the updated formula to your tap repository

## Example brew-tap Repository Structure

```
homebrew-tap/
├── Formula/
│   └── macmonitor.rb
└── README.md
```

The README.md should contain information about available formulas and installation instructions.

## Automatic Updates with GitHub Actions

You can set up GitHub Actions to automatically update your formula when new releases are created:

1. Create a `.github/workflows/update-formula.yml` file in your homebrew-tap repository
2. Define a workflow that triggers on new releases in your main repository
3. The workflow should automatically update the formula's URL and SHA256

This advanced setup can save time when managing multiple releases.
