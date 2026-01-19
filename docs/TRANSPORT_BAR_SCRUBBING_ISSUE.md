# Transport Bar Scrubbing Issue

## Problem Summary

The transport bar scrubbing on tvOS behaves unpredictably. Users experience erratic focus behavior when attempting to scrub through video content using the Siri Remote touchpad.

## Symptoms

1. **Unpredictable scrubbing** - Swipe gestures on the touchpad don't consistently move the playhead
2. **Focus jumping** - Focus unexpectedly moves between transport bar elements
3. **Delayed response** - Scrubbing input feels laggy or unresponsive

## Root Cause Analysis

### Primary Issue: `_UIReplicantView` Warnings

The tvOS focus system uses view replication to create focus effects. When the focus system encounters improperly configured view hierarchies, it generates warnings:

```
Adding '_UIReplicantView' as a subview of UIHostingController.view is not supported
and may result in a broken view hierarchy. Add your view above UIHostingController.view
in a common superview or insert it into your SwiftUI content in a UIViewRepresentable instead.
```

These warnings indicate that the focus replication system is unable to properly create focus effects, resulting in broken focus behavior.

### Secondary Issue: VLC Main Thread Violations

```
Modifying properties of a view's layer off the main thread is not allowed:
view <VLCOpenGLES2VideoView:...>
backtrace: ...-[VLCOpenGLES2VideoView doResetBuffers:] + 164
```

This is an internal TVVLCKit bug where OpenGL buffer operations occur on background threads. Cannot be fixed from app code.

---

## Affected Components

### 1. VideoPlayerContainerView (`Swiftfin tvOS/Views/VideoPlayerContainerState/PlaybackControls/VideoPlayerContainerView.swift`)

Uses `Engine.HostingController` for three child view controllers:
- `playerViewController` - Contains VLC player view
- `playbackControlsViewController` - Contains transport bar and controls
- `supplementContainerViewController` - Contains episode list, etc.

**Architecture:**
```
UIVideoPlayerContainerViewController
├── playerViewController (HostingController<AnyView>)
│   └── view (isUserInteractionEnabled = false)
├── playbackControlsViewController (HostingController<AnyView>)
│   └── view (isUserInteractionEnabled = true)
│       └── SliderContainer (UISliderContainerViewController)
│           ├── progressHostingController.view
│           └── sliderControl (UISliderControl - focusable)
└── supplementContainerViewController (HostingController<AnyView>)
```

### 2. SliderContainer (`Swiftfin tvOS/Components/SliderContainer/SliderContainer.swift`)

**Fixed in commit 6b218484, but warnings persist:**

The original issue was that the hosting controller's view was added to `sliderControl` instead of `self.view`, creating a containment mismatch. This was corrected to:

```swift
// Hosting controller view added to self.view (correct)
addChild(progressHostingController)
view.addSubview(progressHostingController.view)
progressHostingController.didMove(toParent: self)

// SliderControl added on top for focus handling
view.addSubview(sliderControl)
```

### 3. RotateContentView (`Shared/Components/RotateContentView.swift`)

Uses proper containment but creates/destroys hosting controllers dynamically during content rotation.

### 4. Engine Package (`nathantannar4/Engine` v2.3.2)

External dependency providing `HostingController` class. The focus replication warnings reference `Engine.HostingController<AnyView>` in the backtrace.

---

## Technical Deep Dive

### Why `_UIReplicantView` Warnings Occur

On tvOS, when a view becomes focused, UIKit creates a `_UIReplicantView` to render focus effects (scaling, shadows, etc.). This replicant view is added as a sibling to the focused view.

The warning triggers when:
1. A `UIHostingController.view` contains focusable UIKit controls
2. The focus system attempts to add `_UIReplicantView` as a subview of the hosting controller's view
3. SwiftUI's internal view management conflicts with UIKit's focus replication

### The Focus Hierarchy Problem

```
Expected by tvOS Focus System:
CommonSuperview
├── FocusableView
└── _UIReplicantView (sibling)

What Happens with HostingController:
HostingController.view (SwiftUI-managed)
├── FocusableControl
└── _UIReplicantView (attempted, blocked)
```

### Current SliderContainer Architecture

```
UISliderContainerViewController.view
├── progressHostingController.view (SwiftUI content, !isUserInteractionEnabled)
└── sliderControl (UIControl, canBecomeFocused = true)
    └── (receives focus, pan gestures)
```

The sliderControl IS focusable and DOES receive focus correctly now. However, the `_UIReplicantView` warnings still appear because:

1. The `Engine.HostingController` instances in `VideoPlayerContainerView` may not be configured correctly for tvOS focus
2. There may be nested hosting controllers creating conflicting focus environments
3. The `FocusGuide` system may be interacting poorly with UIKit's native focus

---

## Scrubbing Implementation Details

### Gesture Flow

1. **Focus acquisition**: `UISliderControl.didUpdateFocus()` sets `containerState.isFocused = true`
2. **Pan gesture**: `UIPanGestureRecognizer` with `.indirect` touch type (Siri Remote)
3. **Scrub mode entry**: Click or pan start calls `enterScrubMode()`
4. **Value updates**: Pan translation mapped to duration with damping factor
5. **Commit/cancel**: Click commits, Menu cancels, gesture end auto-commits

### Damping Factor

```swift
private var dampingFactor: CGFloat {
    let totalSeconds = CGFloat(total)
    return max(5.0, min(15.0, totalSeconds / 600))
}
```

- 10 min video: dampingFactor = 5.0
- 2 hr video: dampingFactor = 12.0

### State Management

```swift
SliderContainerState<Value>
├── isEditing: Bool     // Currently scrubbing
├── isFocused: Bool     // Slider has focus
├── value: Value        // Current scrubbed position
└── total: Value        // Video duration
```

---

## Attempted Fixes

### Commit 6b218484 (2026-01-18)

**Goal:** Fix `_UIReplicantView` warnings by using proper view controller containment

**Changes:**
1. `SliderContainer`: Refactored from `UIViewRepresentable` to `UIViewControllerRepresentable`
2. Hosting controller view now direct child of VC's view
3. `sliderControl` positioned on top for focus handling

**Result:** Warnings still appear, suggesting other sources

### Current Session Fix

**Change:** Reversed view addition order - hosting controller view first, sliderControl on top

**Result:** Warnings still appear (2 warnings at session start before playback)

---

## Potential Root Causes (Ordered by Likelihood)

### 1. Engine.HostingController Configuration (HIGH)

The `Engine` package's `HostingController` may have properties affecting focus:
- `disablesSafeArea` property is used
- `automaticallyAllowUIKitAnimationsForNextUpdate` is used
- May not be optimized for tvOS focus system

### 2. Nested HostingController Hierarchy (HIGH)

```
VideoPlayerContainerVC
└── playbackControlsViewController (Engine.HostingController)
    └── PlaybackControls (SwiftUI)
        └── SliderContainer (UIViewControllerRepresentable)
            └── UISliderContainerViewController
                └── progressHostingController (Engine.HostingController)
```

Two levels of hosting controllers may confuse the focus system.

### 3. FocusGuide Interactions (MEDIUM)

The `FocusGuide` system routes focus between:
- `actionButtons` (top)
- `playbackProgress` (bottom)

This custom focus routing may conflict with UIKit's native focus engine.

### 4. SwiftUI @FocusState vs UIKit Focus (MEDIUM)

`PlaybackProgress` uses `@FocusState private var isFocused: Bool` alongside UIKit's focus system in `UISliderControl`.

### 5. Dynamic View Creation in RotateContentView (LOW)

Creates/destroys hosting controllers during content rotation, potentially leaving stale focus state.

---

## Recommended Investigation Steps

### Step 1: Isolate the Warning Source

Add logging to identify exactly when/where warnings occur:

```swift
// In UIVideoPlayerContainerViewController.viewDidLoad()
print("FOCUS_DEBUG: Setting up player VC")
// ... after each addChild call
print("FOCUS_DEBUG: Added \(childName) to hierarchy")
```

### Step 2: Test Without Nested HostingController

Modify `SliderContainer` to NOT use a hosting controller for the progress view:
- Use pure UIKit `UIProgressView` instead
- Test if warnings disappear

### Step 3: Check Engine.HostingController Configuration

Review Engine package source for tvOS-specific focus handling:
```bash
# Clone and inspect
git clone https://github.com/nathantannar4/Engine
grep -r "focus" Engine/Sources/
```

### Step 4: Simplify Focus Hierarchy

Test with minimal focus setup:
1. Remove `FocusGuide` routing
2. Use single focusable element
3. Verify basic scrubbing works

### Step 5: File Engine Issue

If Engine.HostingController is the root cause, file issue at:
https://github.com/nathantannar4/Engine/issues

---

## Related Files

| File | Purpose |
|------|---------|
| `SliderContainer.swift` | Scrub gesture handling, focusable UIControl |
| `SliderContainerState.swift` | Observable state for slider |
| `CapsuleSlider.swift` | SwiftUI wrapper for SliderContainer |
| `PlaybackProgress.swift` | Preview images, time display |
| `PlaybackControls.swift` | Transport bar layout, press handling |
| `VideoPlayerContainerView.swift` | Top-level VC containment |
| `FocusGuide.swift` | Custom focus routing |
| `RotateContentView.swift` | Dynamic hosting controller management |

---

## Debug Logging Categories

Current debug logging uses OSLog subsystem `org.jellyfin.swiftfin`:

| Category | Purpose |
|----------|---------|
| `TransportBarFocus` | Focus state changes |
| `ActionButtonsFocus` | Action button focus tracking |
| `AudioButtonDebug` | Audio button rendering |

---

## External Dependencies

| Package | Version | Relevance |
|---------|---------|-----------|
| Engine | 2.3.2 | Provides HostingController |
| TVVLCKit | - | Video playback, main thread violations |
| VLCUI | - | VLC SwiftUI integration |

---

## Next Steps

1. **Immediate**: Add comprehensive focus debugging to identify exact warning source
2. **Short-term**: Test alternative to nested hosting controllers
3. **Medium-term**: Consider pure UIKit transport bar implementation
4. **Long-term**: Report issues to Engine package if confirmed as source

---

## References

- [Apple: Working with Focus in tvOS](https://developer.apple.com/documentation/uikit/focus-based_navigation)
- [Engine Package](https://github.com/nathantannar4/Engine)
- [TVVLCKit](https://code.videolan.org/videolan/VLCKit)

---

*Last updated: 2026-01-18*
*Author: Claude (with Jacob)*
