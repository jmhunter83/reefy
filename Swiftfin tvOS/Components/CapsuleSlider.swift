//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct CapsuleSlider<Value: BinaryFloatingPoint>: View {

    @Binding
    private var value: Value

    private let total: Value
    private var onEditingChanged: (Bool) -> Void
    private var onFocusChanged: (Bool) -> Void

    init(value: Binding<Value>, total: Value) {
        self._value = value
        self.total = total
        self.onEditingChanged = { _ in }
        self.onFocusChanged = { _ in }
    }

    var body: some View {
        SliderContainer(
            value: $value,
            total: total,
            onEditingChanged: onEditingChanged,
            onFocusChanged: onFocusChanged
        ) {
            CapsuleSliderContent()
        }
    }
}

extension CapsuleSlider {

    func onEditingChanged(_ action: @escaping (Bool) -> Void) -> Self {
        copy(modifying: \.onEditingChanged, with: action)
    }

    func onFocusChanged(_ action: @escaping (Bool) -> Void) -> Self {
        copy(modifying: \.onFocusChanged, with: action)
    }
}

private struct CapsuleSliderContent: SliderContentView {

    @EnvironmentObject
    var sliderState: SliderContainerState<Double>

    /// Height: normal 8pt, focused 10pt, editing 12pt
    private var barHeight: CGFloat {
        if sliderState.isEditing {
            return 12
        }
        return sliderState.isFocused ? 10 : 8
    }

    /// Scale: normal 1.0, focused 1.05, editing 1.08
    private var scaleEffect: CGFloat {
        if sliderState.isEditing {
            return 1.08
        }
        return sliderState.isFocused ? 1.05 : 1.0
    }

    var body: some View {
        // Progress bar with visual states
        ProgressView(value: sliderState.value, total: sliderState.total)
            .progressViewStyle(PlaybackProgressViewStyle(cornerStyle: .round))
            .frame(height: barHeight)
            .overlay {
                // Border when focused or editing
                if sliderState.isFocused || sliderState.isEditing {
                    RoundedRectangle(cornerRadius: barHeight / 2)
                        .stroke(
                            sliderState.isEditing ? Color.white.opacity(0.6) : Color.white.opacity(0.3),
                            lineWidth: sliderState.isEditing ? 2 : 1
                        )
                }
            }
            .shadow(
                color: sliderState.isEditing ? Color.white.opacity(0.3) : Color.clear,
                radius: sliderState.isEditing ? 8 : 0
            )
            .scaleEffect(scaleEffect)
            .animation(.easeInOut(duration: 0.2), value: sliderState.isFocused)
            .animation(.easeInOut(duration: 0.15), value: sliderState.isEditing)
    }
}
