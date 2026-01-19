# Transport Bar Redesign

## Overview

Complete redesign of the tvOS video player transport bar to improve usability with the Siri Remote. Replaces the problematic swipe-to-scrub system with a multi-click skip pattern and adds floating side action buttons for audio/subtitle selection.

## Changes Summary

| Component | Before | After |
|-----------|--------|-------|
| **Position** | Bottom 18% of screen | Bottom 10% of screen |
| **Scrubbing** | Interactive swipe-to-scrub | Removed (replaced with multi-click skip) |
| **Skip Navigation** | Hold arrow keys for accelerated scrub | Multi-click arrow keys for discrete jumps |
| **Audio/Subtitles** | In-bar menu buttons | Floating side panel with glass backdrop |
| **Progress Display** | Interactive capsule slider | Static progress bar + timestamps |

---

## Multi-Click Skip System

### How It Works

Press the **left/right arrow keys** on the Siri Remote to skip backward/forward:

| Clicks | Skip Amount | Use Case |
|--------|-------------|----------|
| 1× | 15 seconds | Skip intro/credits, rewind a line |
| 2× | 2 minutes | Skip a scene |
| 3× | 15 minutes | Major chapter jump |

### Behavior

- **Independent mode**: Each click level is a fresh skip from current position (not cumulative)
- **600ms timeout**: Click count resets after 600ms of no input
- **Visual feedback**: Large centered indicator shows skip amount (e.g., "+2:00", "−15:00")
- **Auto-hide**: Skip indicator disappears after 1 second

### Implementation

Located in `PlaybackControls.swift`:

```swift
// Skip amounts: [15s, 2min, 15min]
private let skipAmounts: [Duration] = [
    .seconds(15),
    .seconds(120),
    .seconds(900),
]

@State private var forwardClickCount: Int = 0
@State private var backwardClickCount: Int = 0

private func handleSkip(direction: SkipDirection) {
    // Increment click count (max 3)
    // Execute skip with skipAmounts[clickCount - 1]
    // Reset click count after 600ms timeout
}
```

---

## Side Action Buttons

### Layout

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│                                                  ┌─────────────┐ │
│                                                  │  🔊 Audio   │ │
│                                                  ├─────────────┤ │
│                                                  │ 💬 Subtitles│ │
│                                                  └─────────────┘ │
│                                                  (glass backdrop) │
├──────────────────────────────────────────────────────────────────┤
│  [⏮]  00:23:45 ━━━━━━━━━━○━━━━━━━━━ -01:12:30  [⏭] [📺]        │
│              ← → Skip: 1×=15s  2×=2min  3×=15min                 │
└──────────────────────────────────────────────────────────────────┘
```

### Features

- **Floating glass panel**: Uses `TransportBarBackground` for consistent Liquid Glass styling
- **Button order**: Audio (top), Subtitles (bottom) - subtitle button closer to transport bar for easier navigation
- **Position**: Above transport bar on right edge, `padding(.top, 400)`
- **Focus guide**: Registered with tag `"sideButtons"`, navigates down to `"transportBar"`

### InlineStreamPicker

Custom dropdown component for audio/subtitle track selection:

- Collapsed: Shows button with icon and label
- Expanded: Scrollable list with checkmark for selected track
- Uses `formattedAudioTitle` / `formattedSubtitleTitle` from MediaStream extension
- "None" option for subtitles

---

## Transport Bar Content

### Current Layout (Left to Right)

1. **Play Previous** - Jump to previous episode (if available)
2. **Progress Display** - Static bar + timestamps (non-interactive)
3. **Play Next** - Jump to next episode (if available)
4. **Episodes** - Open episode list panel

### Removed Elements

- Skip backward/forward buttons (replaced with arrow key handling)
- Interactive scrub slider (replaced with static progress)

---

## Files Changed

| File | Changes |
|------|---------|
| `PlaybackControls.swift` | Arrow key handling, multi-click logic, layout restructure |
| `PlaybackProgress.swift` | Removed CapsuleSlider, static progress bar only |
| `SideActionButtons.swift` | New floating glass panel with Audio/Subtitles |
| `InlineStreamPicker.swift` | New custom dropdown for stream selection |
| `ActionButtons.swift` | Removed audio/subtitles from transport bar exclusions |

---

## Focus Navigation

```
                    ┌─────────────┐
                    │ Side Buttons│
                    │ (Audio/Subs)│
                    └──────┬──────┘
                           │ ↓ (down)
┌──────────────────────────┴───────────────────────────┐
│                    Transport Bar                      │
│  [⏮] ←→ [Progress] ←→ [⏭] ←→ [📺]                   │
└──────────────────────────────────────────────────────┘
```

- **Arrow keys** (when not focused on buttons): Trigger multi-click skip
- **Up from transport bar**: Navigate to side buttons
- **Down from side buttons**: Return to transport bar

---

## Why This Design?

### Problems with Previous System

1. **Swipe-to-scrub unreliable**: Siri Remote touchpad gestures conflicted with focus system
2. **`_UIReplicantView` warnings**: Focus replication failed on interactive slider
3. **Hold-to-scrub confusing**: Users didn't discover the hold behavior

### Benefits of New System

1. **Discrete jumps**: Predictable skip amounts, no accidental overshoots
2. **No focus conflicts**: Arrow keys work regardless of UI focus state
3. **Discoverable**: Explainer label shows skip pattern
4. **Scalable**: 15min skip useful for movies, 15s for dialogue-heavy content

---

## Future Improvements

- [ ] Persist user's preferred skip amounts in settings
- [ ] Add haptic feedback on skip (if tvOS supports)
- [ ] Consider swipe gesture for fine-grained scrub (optional mode)
- [ ] Chapter-aware skipping (jump to next chapter marker)
