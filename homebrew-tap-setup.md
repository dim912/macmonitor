# Setting Up a Homebrew Tap for Mac System Monitor

This guide explains how to set up your own Homebrew tap repository to distribute Mac System Monitor via Homebrew.

## What is a Homebrew Tap?

A tap is a repository of Homebrew formulae. Creating your own tap allows you to distribute your software via Homebrew without needing to get it accepted into the main Homebrew repository.

## Steps to Create a Tap

1. **Create a GitHub Repository**

   Create a new GitHub repository named `homebrew-macmonitor` (the prefix `homebrew-` is required by convention).

2. **Add the Formula File**

   Copy the `macmonitor.rb` file into your repository.

3. **Update the URL and SHA256**

   Before distributing, make sure to:
   - Create a proper release of your Mac System Monitor on GitHub
   - Update the URL in the formula to point to your release
   - Calculate and update the SHA256 hash of your release tarball:
     ```bash
     curl -sL https://github.com/yourusername/mac-system-monitor/archive/refs/tags/v1.0.0.tar.gz | shasum -a 256
     ```

4. **Commit and Push**

   ```bash
   git add macmonitor.rb
   git commit -m "Add Mac System Monitor formula"
   git push
   ```

5. **Test Your Tap**

   ```bash
   brew tap yourusername/macmonitor
   brew install macmonitor
   ```

## Installation Instructions for Users

Add the following instructions to your README.md:

```markdown
## Installation via Homebrew

You can install Mac System Monitor using Homebrew:

```bash
# Add the tap
brew tap yourusername/macmonitor

# Install Mac System Monitor
brew install macmonitor
```

## Usage After Homebrew Installation

After installing via Homebrew, you can use the following simple commands:

```bash
mm cli                # Show stats in CLI with auto-update
mm test               # Test available metrics
mm restart            # Start/restart monitoring service
mm uninstall          # Remove the monitoring service
mm help               # Display detailed help information
