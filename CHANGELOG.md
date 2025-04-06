# Changelog

All notable changes to the Mac System Monitor project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- GitHub repository structure with issue templates and PR template
- CI workflow with ShellCheck for code quality
- Improved documentation (CODE_OF_CONDUCT.md, CONTRIBUTING.md)
- MIT License

## [1.0.0] - 2025-04-06

### Added
- Initial release
- Real-time monitoring of CPU temperature, GPU temperature, fan speeds
- Monitoring of WindowServer CPU usage, memory pressure, swap usage
- Automatic alerting for abnormal system conditions
- Daily logging of system metrics with auto-cleanup
- Installation, update, and uninstall scripts
- Support for all macOS users with user-specific services

### Changed
- Integrated GPU temperature setup into main installer

### Fixed
- GPU temperature monitoring with passwordless sudo configuration
