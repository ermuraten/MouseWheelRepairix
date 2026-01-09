# Changelog

All notable changes to MouseWheelRepairix will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-01-08

### Added
- Wheel click interval measurement tool
- Real-time display of click timing in dedicated window
- Shows last 10 click intervals in milliseconds
- Average interval calculation
- Modern UI with blue header and improved typography
- Helps users optimize debounce settings

### Fixed
- Measurement window now appears immediately on first open
- Window close button (X) now works properly
- Fixed crash when reopening measurement window

## [1.0.0] - 2026-01-08

### Added
- Mouse wheel event debouncing to fix erratic scrolling behavior
- Configurable debounce times: 50ms, 100ms, 200ms
- Custom debounce time input for fine-tuned control
- Menu bar integration with custom mouse icon
- Toggle to enable/disable mouse wheel repair functionality
- Start at login functionality via LaunchAgents
- Accessibility permissions handling
- Dark/light mode adaptive menu bar icon
- Status indicator in menu (Active/Inactive)

### Technical
- Swift Package Manager project structure
- macOS 11+ compatibility
- Event tap implementation for mouse wheel interception
- LaunchAgent plist generation for auto-start

[1.0.0]: https://github.com/yourusername/MouseWheelRepairix/releases/tag/v1.0.0
