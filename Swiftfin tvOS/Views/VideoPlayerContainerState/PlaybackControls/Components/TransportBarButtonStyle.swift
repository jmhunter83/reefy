//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// MARK: - Shared Focus Styling

/// View modifier that applies consistent tvOS transport bar focus styling.
/// Used by both TransportBarButton and TransportBarMenu to avoid duplication.
private struct TransportBarFocusStyle: ViewModifier {

    let isFocused: Bool

    func body(content: Content) -> some View {
        content
            .font(.title2)
            .fontWeight(.medium)
            .foregroundStyle(isFocused ? .black : .white.opacity(0.9))
            .padding(.horizontal, isFocused ? 24 : 8)
            .padding(.vertical, isFocused ? 16 : 8)
            .background {
                if isFocused {
                    Capsule().fill(Color.white)
                } else {
                    Capsule().fill(.ultraThinMaterial.opacity(0.3))
                }
            }
            .clipShape(Capsule())
    }
}

/// View modifier for the outer container focus effects (scale, shadow, animation).
private struct TransportBarFocusEffects: ViewModifier {

    let isFocused: Bool

    func body(content: Content) -> some View {
        content
            .scaleEffect(isFocused ? 1.1 : 1.0)
            .shadow(
                color: isFocused ? .black.opacity(0.4) : .clear,
                radius: isFocused ? 15 : 0,
                x: 0,
                y: isFocused ? 10 : 0
            )
            .animation(.easeOut(duration: 0.15), value: isFocused)
    }
}

// MARK: - Transport Bar Button

/// Button with native Apple TV focus behavior (lift and glow effect).
struct TransportBarButton<Label: View>: View {

    var focusBinding: FocusState<VideoPlayerActionButton?>.Binding
    let buttonType: VideoPlayerActionButton
    let action: () -> Void
    let label: () -> Label

    private var isFocused: Bool {
        focusBinding.wrappedValue == buttonType
    }

    init(
        focusBinding: FocusState<VideoPlayerActionButton?>.Binding,
        buttonType: VideoPlayerActionButton,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.focusBinding = focusBinding
        self.buttonType = buttonType
        self.action = action
        self.label = label
    }

    var body: some View {
        Button(action: action) {
            label()
                .modifier(TransportBarFocusStyle(isFocused: isFocused))
        }
        .buttonStyle(.plain)
        .focused(focusBinding, equals: buttonType)
        .modifier(TransportBarFocusEffects(isFocused: isFocused))
    }
}

// MARK: - Transport Bar Menu

/// Menu with native Apple TV focus behavior. Keeps overlay visible while menu is open.
struct TransportBarMenu<Label: View, Content: View>: View {

    @EnvironmentObject
    private var containerState: VideoPlayerContainerState

    var focusBinding: FocusState<VideoPlayerActionButton?>.Binding
    let buttonType: VideoPlayerActionButton

    private var isFocused: Bool {
        focusBinding.wrappedValue == buttonType
    }

    @State
    private var wasFocused = false
    @State
    private var menuOpenPokeTask: Task<Void, Never>?

    let title: String
    let label: () -> Label
    let content: () -> Content

    init(
        _ title: String,
        focusBinding: FocusState<VideoPlayerActionButton?>.Binding,
        buttonType: VideoPlayerActionButton,
        @ViewBuilder label: @escaping () -> Label,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.focusBinding = focusBinding
        self.buttonType = buttonType
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
        .focused(focusBinding, equals: buttonType)
        .modifier(TransportBarFocusEffects(isFocused: isFocused))
        .onChange(of: isFocused) { _, newValue in
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
