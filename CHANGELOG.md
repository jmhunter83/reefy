# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## [Unreleased]

### Changed

- **VideoPlayerContainerState**: Migrated from dual boolean/enum state representation to enum-only source of truth with computed properties for backward compatibility. Enums (`OverlayVisibility`, `SupplementVisibility`, `ScrubState`) are now the canonical state representation.

### Added

- **iOS-Style Video Player Controls** (tvOS): Complete overhaul of video player controls adapted from upstream iOS Swiftfin:
  - **Center Playback Buttons**: Large play/pause and jump forward/backward buttons centered on screen
    - Native tvOS focus effects with spring animations
    - Liquid Glass backgrounds on tvOS 26+
    - Dynamically shown/hidden based on live stream status
  - **Info Button**: Opens MediaInfoSupplement panel showing poster, title, overview, ratings
    - Note: Uses literal "Information" string (L10n.info not in en.lproj; translations exist in other locales)
  - **Episodes Button**: Opens episode selector for series content with season picker
  - **Chapter Track Mask**: iOS-style inverse mask technique for chapter dividers (cleaner than overlays)
  - **Button Grouping**: Organized action buttons into logical groups with visual spacing:
    - Queue (Previous/Next/AutoPlay)
    - Tracks (Subtitles/Audio)
    - Content (Info/Episodes)
    - Settings (Speed/Quality)
    - View (AspectFill)

- **NetworkError**: Restored typed network error handling with:
  - Factory methods: `from(urlErrorCode:)` and `from(httpStatusCode:message:)`
  - Error cases: `timeout`, `hostNotFound`, `cannotConnect`, `connectionLost`, `noConnection`, `sslError`, `unauthorized`, `forbidden`, `notFound`, `serverError`, `badRequest`
  - `isRecoverable` property for retry logic
  - `errorTitle` property for UI display

- **MediaError**: New domain-specific error type for media playback with:
  - Error cases: `noPlayableSource`, `unsupportedFormat`, `transcodingFailed`, `streamEnded`, `loadFailed`, `itemNotFound`, `noMediaInfo`, `notPlayable`, `sessionCreationFailed`, `sessionExpired`, `reportingFailed`
  - `isRetryable` property for retry logic
  - `errorTitle` property for UI display

- **Test Files** (pending Xcode target integration):
  - `VideoPlayerContainerStateTests.swift` - State transition tests
  - `NetworkErrorTests.swift` - Factory method and property tests
  - `MediaErrorTests.swift` - Error description and retryability tests

### Removed

- Removed dual state sync code from `VideoPlayerContainerState` (`didSet` observers that synced booleans to enums)
- Removed commented-out legacy `NetworkError` implementation

---

## Previous Releases

See git history for changes prior to this changelog.
