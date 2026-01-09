# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Reefy** is a native tvOS Jellyfin client, forked from Swiftfin. It focuses exclusively on Apple TV with VLC-based playback and tvOS 18 Liquid Glass effects.

- **Target**: tvOS 17+ (tvOS 18 for Liquid Glass)
- **Language**: Swift 5.9+
- **Build Tool**: Xcode 16.4+

## Build Commands

```bash
# Install dependencies (one-time)
brew install carthage swiftformat swiftgen

# Update Carthage dependencies
carthage update --use-xcframeworks --cache-builds

# Format code (required before PR)
swiftformat .
```

## Development Setup

1. Create `XcodeConfig/DevelopmentTeam.xcconfig`:
```
DEVELOPMENT_TEAM = YOUR_TEAM_ID
PRODUCT_BUNDLE_IDENTIFIER = org.jellyfin.swiftfin
```

2. Open `Swiftfin.xcodeproj` in Xcode
3. Wait for SPM packages to resolve
4. Select scheme: **Swiftfin tvOS**

## Architecture

### Directory Structure
- `Shared/` — 80% of code; cross-platform business logic, ViewModels, Services
- `Swiftfin tvOS/` — tvOS-specific views and components
- `PreferencesView/` — SPM package for preference system
- `Scripts/Translations/` — Localization scripts

### Key Patterns

**MVVM with Coordinators:**
- `RootCoordinator` — Global app state, authentication
- `TabCoordinator` — Tab management
- `NavigationCoordinator` — Per-tab navigation stacks

**Dependency Injection (Factory):**
```swift
@Injected(\.currentUserSession) var userSession: UserSession!
```

**State Management (Stateful protocol):**
```swift
final class HomeViewModel: ViewModel, Stateful {
    enum Action { case refresh }
    enum State { case initial, refreshing, content }
    func respond(to action: Action) -> State { ... }
}
```

**Type-safe Notifications:**
```swift
Notifications[.didSignIn].publisher.sink { ... }
Notifications[.itemMetadataDidChange].post(item)
```

### Data Layer
- **JellyfinAPI** — Server communication via Jellyfin SDK
- **CoreStore** — SQLite persistence (V2 schema)
- **Defaults** — Two-tier settings: app-wide + per-user

### Video Playback
- **VLCKit** — Primary player (broad codec support)
- **AVKit** — Alternative (better HDR, energy efficiency)

## Key Files

| Area | Location |
|------|----------|
| App Entry | `Swiftfin tvOS/App/SwiftfinApp.swift` |
| Root State | `Shared/Coordinators/Root/RootCoordinator.swift` |
| ViewModel Base | `Shared/ViewModels/ViewModel.swift` |
| User Session | `Shared/Services/UserSession.swift` |
| Persistence | `Shared/SwiftfinStore/` |
| Errors | `Shared/Errors/NetworkError.swift`, `MediaError.swift` |
| Video Player | `Shared/Objects/MediaPlayerManager/` |

## Code Style

- **SwiftFormat** config in `.swiftformat`
- 4-space indentation, 140 char line width
- No semicolons, short optional syntax (`?` not `Optional`)
- Use `// MARK:` for code organization

## PR Requirements

- SwiftFormat linting must pass
- tvOS build must succeed
- New user-facing strings must be localized
- No developer account credentials in commits

## Testing

Test files in `Swiftfin tvOS Tests/`:
- `VideoPlayerContainerStateTests.swift`
- `NetworkErrorTests.swift`
- `MediaErrorTests.swift`

## Useful Commands

```bash
# Run SwiftFormat check (CI uses this)
swiftformat --lint .

# Alphabetize localization strings
swift Scripts/Translations/AlphabetizeStrings.swift

# Remove unused localization strings
swift Scripts/Translations/PurgeUnusedStrings.swift
```
