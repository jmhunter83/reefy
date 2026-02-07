# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## [1.0.0] - App Store Release

**App Store Release**: Reefy is now live on the Apple App Store in 175 countries.

**Version**: 1.0.0 (Build 81)
**Availability**: 175 countries worldwide
**Installation**: Search "Reefy Media Player" on Apple TV App Store

### Added

- **Audio Output Mode Setting**: New setting to control surround sound downmix behavior (`Settings → Video Player → Audio`)
  - **Auto** (default): Disables passthrough so VLC properly downmixes surround to stereo
  - **Stereo**: Force 2-channel output as fallback
  - **Passthrough**: Send raw audio to receiver (requires compatible hardware)
  - Fixes center channel going to left speaker only on stereo setups (#19)

- **Liquid Glass UI**: Applied tvOS 18 Liquid Glass effects to playback controls

- **iOS-Style Video Player Controls** (tvOS): Complete overhaul of video player controls adapted from upstream iOS Swiftfin:
  - **Center Playback Buttons**: Large play/pause and jump forward/backward buttons centered on screen
    - Native tvOS focus effects with spring animations
    - Liquid Glass backgrounds on tvOS 18+
    - Dynamically shown/hidden based on live stream status
  - **Info Button**: Opens MediaInfoSupplement panel showing poster, title, overview, ratings
  - **Episodes Button**: Opens episode selector for series content with season picker
  - **Chapter Track Mask**: iOS-style inverse mask technique for chapter dividers
  - **Button Grouping**: Organized action buttons into logical groups with visual spacing

- **NetworkError**: Restored typed network error handling with factory methods and `isRecoverable` property

- **MediaError**: New domain-specific error type for media playback with `isRetryable` property

- **Test Files** (pending Xcode target integration):
  - `VideoPlayerContainerStateTests.swift`, `NetworkErrorTests.swift`, `MediaErrorTests.swift`

### Fixed

- **Button Overlap**: Resolved movie detail view button overlap (#14)
- **Initial Focus**: Fixed initial focus not being set on TV Show detail view (#2)
- **Focus Loop**: Resolved action button focus loop issue
- **VLC Thread Safety**: Ensured VLC callbacks dispatch to main thread
- **Intro Skipper**: Temporarily disabled due to build conflicts (will revisit in dedicated sprint)

### Changed

- **VideoPlayerContainerState**: Migrated from dual boolean/enum state representation to enum-only source of truth with computed properties for backward compatibility. Enums (`OverlayVisibility`, `SupplementVisibility`, `ScrubState`) are now the canonical state representation.

### Removed

- Removed dual state sync code from `VideoPlayerContainerState` (`didSet` observers that synced booleans to enums)
- Removed commented-out legacy `NetworkError` implementation

---

## [Unreleased]

### Added

(empty - ready for future work)

### Fixed

- **Home Screen Empty State**: Prevented the cinematic recently added section from rendering as a blank hero area when no items are returned, and added an explicit Home empty-state view when all Home sections are empty.

### Changed

(empty - ready for future work)

### Removed

(empty - ready for future work)

---

## Previous Releases

See git history for changes prior to this changelog.
