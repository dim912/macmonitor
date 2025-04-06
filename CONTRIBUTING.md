# Contributing to Mac System Monitor

Thank you for your interest in contributing to Mac System Monitor! This document provides guidelines and instructions for contributing to this project.

## Code of Conduct

By participating in this project, you are expected to uphold our [Code of Conduct](CODE_OF_CONDUCT.md).

## How Can I Contribute?

### Reporting Bugs

This section guides you through submitting a bug report. Following these guidelines helps maintainers understand your report and reproduce the issue.

1. **Use the GitHub issue tracker** — Check if the bug has already been reported by searching on GitHub under [Issues](https://github.com/yourusername/mac-system-monitor/issues).
2. **Use the bug report template** — If you're unable to find an open issue addressing the problem, [open a new one](https://github.com/yourusername/mac-system-monitor/issues/new?template=bug_report.md) using the bug report template.
3. **Provide detailed information** — Include as many details as possible: steps to reproduce, expected vs. actual behavior, and your environment details.

### Suggesting Enhancements

This section guides you through submitting an enhancement suggestion, including completely new features and minor improvements to existing functionality.

1. **Use the GitHub issue tracker** — Check if the enhancement has already been suggested by searching on GitHub under [Issues](https://github.com/yourusername/mac-system-monitor/issues).
2. **Use the feature request template** — If you're unable to find an open issue describing your suggested enhancement, [open a new one](https://github.com/yourusername/mac-system-monitor/issues/new?template=feature_request.md) using the feature request template.

### Pull Requests

1. **Fork the repository** — Create your own fork of the project.
2. **Create a branch** — Create a branch in your fork for your contribution.
3. **Make your changes** — Make your changes on your branch.
4. **Test your changes** — Ensure your changes do not break existing functionality.
5. **Submit a pull request** — Open a pull request using our template.

## Development Guidelines

### Shell Scripting Style

* Use 4 spaces for indentation
* Add comments for complex logic
* Follow [Google's Shell Style Guide](https://google.github.io/styleguide/shellguide.html) where applicable

### Testing

* Test your changes on different macOS versions if possible
* Run the `test_monitor.sh` script to verify basic functionality
* For major changes, test on both Intel and Apple Silicon Macs if available

### Documentation

* Update the README.md if you change functionality
* Document new features or significant changes
* Ensure command examples are correct and tested

## Getting Started

To get started with development:

1. Clone the repository
   ```
   git clone https://github.com/yourusername/mac-system-monitor.git
   cd mac-system-monitor
   ```

2. Make scripts executable
   ```
   chmod +x *.sh
   ```

3. Make your changes and test them
   ```
   ./test_monitor.sh
   ```

## Acknowledgements

Thank you to all the contributors who have helped make Mac System Monitor better!
