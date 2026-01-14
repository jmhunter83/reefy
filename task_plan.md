# Task Plan: Fix Transport Bar Navigation (Native Focus Approach)

## Goal
Resolve focus navigation issues in the transport bar (stuck on Subtitles, unable to move Left/Right) by refactoring to use native SwiftUI focus environment values instead of manual binding passing.

## Problem
Currently, `ActionButtons` passes a `FocusState.Binding` down through multiple layers (`Audio`, `TransportBarButton`, etc.). This manual state management likely conflicts with the native focus engine, causing "focus traps" where the system refuses to move focus because the state update cycle is too rigid or complex.

## Solution
Decouple focus *identity* (managed by parent) from visual *state* (managed by child).
1.  **Parent (`ActionButtons`):** Keep `@FocusState` to track *which* button is focused (for default focus and timer logic). Apply `.focused($state, equals: id)` to the child views externally.
2.  **Children (`TransportBarButton`/`Menu`):** Remove all manual focus bindings. Use `@Environment(\.isFocused)` to detect focus status for styling (glow/scale).

## Phases
- [ ] Phase 1: Refactor `TransportBarButton` and `TransportBarMenu`
    - [ ] Update `TransportBarButton` to remove `focusBinding` and use `@Environment(\.isFocused)`.
    - [ ] Update `TransportBarMenu` to remove `focusBinding` and use `@Environment(\.isFocused)`.
- [ ] Phase 2: Refactor Individual Button Components
    - [ ] Update all 10+ button components (`Audio`, `Subtitles`, etc.) to remove `focusBinding` and `buttonType` parameters.
- [ ] Phase 3: Update `ActionButtons` Container
    - [ ] Apply `.focused($focusedButton, equals: button)` inside the `ForEach` loop in `ActionButtons.swift`.
- [ ] Phase 4: Verify
    - [ ] Build and ensure no compilation errors.
    - [ ] (User) Verify navigation works freely between buttons.

## Key Questions
1. Does `Menu` correctly report `isFocused` on tvOS when its label is highlighted? (Yes, typically).

## Status
**Pending**