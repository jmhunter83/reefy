//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// MARK: - Native tvOS Focus Button

/// A button wrapper that provides native Apple TV focus behavior
/// with the signature "lift and glow" effect.
///
/// NOTE: This is a visual component only. Focus state is managed by the parent
/// ActionButtons view using a single @FocusState to enable proper horizontal navigation.
struct TransportBarButton<Label: View>: View {

    let isFocused: Bool
    let action: () -> Void
    let label: () -> Label

    init(
        isFocused: Bool,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.isFocused = isFocused
        self.action = action
        self.label = label
    }

    var body: some View {
        Button(action: action) {
            label()
                .font(.title2)
                .fontWeight(.medium)
                .foregroundStyle(isFocused ? .black : .white.opacity(0.9))
                // Padding only when focused for capsule background
                .padding(.horizontal, isFocused ? 24 : 8)
                .padding(.vertical, isFocused ? 16 : 8)
                .background {
                    backgroundView
                }
                // Clip to capsule shape
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        // Native Apple TV focus effect: lift + shadow
        .scaleEffect(isFocused ? 1.1 : 1.0)
        .shadow(
            color: isFocused ? .black.opacity(0.4) : .clear,
            radius: isFocused ? 15 : 0,
            x: 0,
            y: isFocused ? 10 : 0
        )
        // Use linear animation to reduce main thread load (prevents audio crackling)
        .animation(.easeOut(duration: 0.15), value: isFocused)
    }

    @ViewBuilder
    private var backgroundView: some View {
        if isFocused {
            // Focused: solid white capsule (Apple TV standard)
            Capsule().fill(Color.white)
        } else {
            // Unfocused: subtle glass effect, icon-only appearance
            Capsule().fill(.ultraThinMaterial.opacity(0.3))
        }
    }
}

// MARK: - Transport Bar Menu Button

/// A menu wrapper with native focus behavior.
///
/// NOTE: This is a visual component only. Focus state is managed by the parent
/// ActionButtons view using a single @FocusState to enable proper horizontal navigation.
struct TransportBarMenu<Label: View, Content: View>: View {

    @EnvironmentObject
    private var containerState: VideoPlayerContainerState

    let isFocused: Bool

    /// Tracks if we were focused (to detect menu open when focus leaves)
    @State
    private var wasFocused: Bool = false

    /// Task that continuously pokes timer while menu is open
    @State
    private var menuOpenPokeTask: Task<Void, Never>?

    let title: String
    let label: () -> Label
    let content: () -> Content

    init(
        _ title: String,
        isFocused: Bool,
        @ViewBuilder label: @escaping () -> Label,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.isFocused = isFocused
        self.label = label
        self.content = content
    }

    var body: some View {
        Menu {
            content()
        } label: {
            label()
                .font(.title2)
                .fontWeight(.medium)
                .foregroundStyle(isFocused ? .black : .white.opacity(0.9))
                // Padding only when focused for capsule background
                .padding(.horizontal, isFocused ? 24 : 8)
                .padding(.vertical, isFocused ? 16 : 8)
                .background {
                    backgroundView
                }
                // Clip to capsule shape
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .scaleEffect(isFocused ? 1.1 : 1.0)
        .shadow(
            color: isFocused ? .black.opacity(0.4) : .clear,
            radius: isFocused ? 15 : 0,
            x: 0,
            y: isFocused ? 10 : 0
        )
        // Use linear animation to reduce main thread load (prevents audio crackling)
        .animation(.easeOut(duration: 0.15), value: isFocused)
        // Handle menu open state - keep overlay visible while browsing menu
        .onChange(of: isFocused) { _, newValue in
            if newValue {
                // Button became focused - cancel any existing poke task
                menuOpenPokeTask?.cancel()
                menuOpenPokeTask = nil
                wasFocused = true
            } else if wasFocused {
                // Focus left after we were focused - menu likely opened
                // Start continuous poke to keep overlay visible while browsing menu
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
        .onDisappear {
            menuOpenPokeTask?.cancel()
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        if isFocused {
            // Focused: solid white capsule (Apple TV standard)
            Capsule().fill(Color.white)
        } else {
            // Unfocused: subtle glass effect, icon-only appearance
            Capsule().fill(.ultraThinMaterial.opacity(0.3))
        }
    }
}

// MARK: - Legacy ButtonStyle (kept for compatibility)

/// Button style for transport bar action buttons
/// Note: Prefer TransportBarButton for proper focus handling
struct TransportBarButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3)
            .fontWeight(.medium)
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background {
                if #available(tvOS 18.0, *) {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .opacity(configuration.isPressed ? 1.0 : 0.8)
                } else {
                    Capsule()
                        .fill(.white.opacity(configuration.isPressed ? 0.5 : 0.3))
                }
            }
            .scaleEffect(configuration.isPressed ? 1.05 : 1.0)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}
