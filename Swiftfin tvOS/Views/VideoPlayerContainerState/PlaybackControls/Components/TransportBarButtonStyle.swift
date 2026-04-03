//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import os.log
import SwiftUI

private let focusLog = Logger(subsystem: "org.jellyfin.swiftfin", category: "TransportBarFocus")

// MARK: - Shared Focus Styling

/// View modifier that applies consistent tvOS transport bar focus styling.
/// Uses modern Liquid Glass design for tvOS 26+ with compact circular buttons.
private struct TransportBarFocusStyle: ViewModifier {

    let isFocused: Bool

    func body(content: Content) -> some View {
        ZStack {
            // Glass background layer
            if #available(tvOS 26.0, *) {
                Circle()
                    .fill(.clear)
                    .glassEffect(
                        isFocused
                            ? .regular.tint(.white.opacity(0.3))
                            : .regular
                    )
            } else {
                Circle()
                    .fill(.ultraThinMaterial)
                    .opacity(isFocused ? 1.0 : 0.7)
            }

            // Icon layer - isolated from glass vibrancy
            content
                .font(.title2)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .compositingGroup()
        }
        .frame(width: 48, height: 48)
    }
}

/// View modifier for the outer container focus effects (scale, shadow, animation).
private struct TransportBarFocusEffects: ViewModifier {

    let isFocused: Bool
    let debugLabel: String

    init(isFocused: Bool, debugLabel: String = "unknown") {
        self.isFocused = isFocused
        self.debugLabel = debugLabel
    }

    func body(content: Content) -> some View {
        let _ = focusLog.trace("   ⚡ TransportBarFocusEffects[\(debugLabel)] isFocused=\(isFocused)")

        return content
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .shadow(
                color: isFocused ? .black.opacity(0.2) : .clear,
                radius: isFocused ? 8 : 0,
                x: 0,
                y: isFocused ? 6 : 0
            )
            .animation(.spring(duration: 0.2), value: isFocused)
    }
}

// MARK: - Transport Bar Button

/// Button with native Apple TV focus behavior using modern Liquid Glass design.
struct TransportBarButton<Label: View>: View {

    @Environment(\.isFocused)
    private var isFocused

    let debugLabel: String
    let action: () -> Void
    let label: () -> Label

    init(
        _ debugLabel: String = "button",
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.debugLabel = debugLabel
        self.action = action
        self.label = label
    }

    var body: some View {
        Button(action: action) {
            label()
                .modifier(TransportBarFocusStyle(isFocused: isFocused))
        }
        .buttonStyle(.plain)
        .modifier(TransportBarFocusEffects(isFocused: isFocused, debugLabel: debugLabel))
    }
}

// MARK: - Transport Bar Menu

/// Menu with native Apple TV focus behavior. Keeps overlay visible while menu is open.
struct TransportBarMenu<Label: View, Content: View>: View {

    @Environment(\.isFocused)
    private var isFocused

    @EnvironmentObject
    private var containerState: VideoPlayerContainerState

    @State
    private var wasFocused = false
    @State
    private var menuOpenPokeTask: Task<Void, Never>?
    @State
    private var lastFocusTime: UInt64 = 0

    let title: String
    let label: () -> Label
    let content: () -> Content

    init(
        _ title: String,
        @ViewBuilder label: @escaping () -> Label,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.label = label
        self.content = content
    }

    var body: some View {
        Menu {
            content()
        } label: {
            label()
                .modifier(TransportBarFocusStyle(isFocused: isFocused))
        }
        .buttonStyle(.plain)
        .modifier(TransportBarFocusEffects(isFocused: isFocused, debugLabel: title))
        .onChange(of: isFocused) { oldValue, newValue in
            let now = DispatchTime.now().uptimeNanoseconds
            let deltaUs = lastFocusTime > 0 ? (now - lastFocusTime) / 1000 : 0
            lastFocusTime = now

            focusLog.debug("🎭 '\(title)': \(oldValue) → \(newValue) [+\(deltaUs)µs]")
            handleFocusChange(newValue)
        }
        .onDisappear {
            menuOpenPokeTask?.cancel()
        }
    }

    private func handleFocusChange(_ newValue: Bool) {
        if newValue {
            menuOpenPokeTask?.cancel()
            menuOpenPokeTask = nil
            wasFocused = true
        } else if wasFocused {
            wasFocused = false
            menuOpenPokeTask?.cancel()
            menuOpenPokeTask = Task { @MainActor in
                while !Task.isCancelled {
                    containerState.timer.poke()
                    try? await Task.sleep(for: .seconds(3))
                }
            }
        }
    }
}

// MARK: - Legacy Button Style

/// Button style for transport bar action buttons.
/// Note: Prefer TransportBarButton for proper focus handling.
struct TransportBarButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3)
            .fontWeight(.medium)
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background {
                Circle()
                    .fill(.ultraThinMaterial)
                    .opacity(configuration.isPressed ? 1.0 : 0.8)
            }
            .scaleEffect(configuration.isPressed ? 1.05 : 1.0)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}
