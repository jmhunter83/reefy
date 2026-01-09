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

    init(value: Binding<Value>, total: Value) {
        self._value = value
        self.total = total
        self.onEditingChanged = { _ in }
    }

    var body: some View {
        SliderContainer(
            value: $value,
            total: total,
            onEditingChanged: onEditingChanged
        ) {
            CapsuleSliderContent()
        }
    }
}

extension CapsuleSlider {

    func onEditingChanged(_ action: @escaping (Bool) -> Void) -> Self {
        copy(modifying: \.onEditingChanged, with: action)
    }
}

private struct CapsuleSliderContent: SliderContentView {

    @EnvironmentObject
    var sliderState: SliderContainerState<Double>

    /// Height: normal 8pt, focused 10pt, editing 14pt
    private var barHeight: CGFloat {
        if sliderState.isEditing {
            return 14
        } else if sliderState.isFocused {
            return 10
        } else {
            return 8
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            // Skip mode indicator - shown when clicks detected
            if sliderState.isEditing {
                HStack(spacing: 4) {
                    // Back arrow and time
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                    Text(sliderState.currentSkipLabel)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))

                    // Divider
                    Text("|")
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.horizontal, 6)

                    // Forward time and arrow
                    Text(sliderState.currentSkipLabel)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay {
                            Capsule()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }

            // Progress bar with visual states
            ProgressView(value: sliderState.value, total: sliderState.total)
                .progressViewStyle(PlaybackProgressViewStyle(cornerStyle: .round))
                .frame(height: barHeight)
                .overlay {
                    // Glow border when editing
                    if sliderState.isEditing {
                        RoundedRectangle(cornerRadius: barHeight / 2)
                            .stroke(Color.white.opacity(0.6), lineWidth: 2)
                            .shadow(color: .white.opacity(0.4), radius: 8)
                    } else if sliderState.isFocused {
                        RoundedRectangle(cornerRadius: barHeight / 2)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    }
                }
                .scaleEffect(sliderState.isEditing ? 1.1 : (sliderState.isFocused ? 1.05 : 1.0))
                .animation(.easeInOut(duration: 0.2), value: sliderState.isFocused)
                .animation(.easeInOut(duration: 0.15), value: sliderState.isEditing)
        }
        .animation(.easeInOut(duration: 0.2), value: sliderState.isEditing)
    }
}
