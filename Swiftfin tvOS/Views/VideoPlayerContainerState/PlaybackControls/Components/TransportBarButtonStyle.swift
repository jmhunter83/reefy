//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

/// Button style for transport bar action buttons
/// Uses Liquid Glass on tvOS 26+, materials on tvOS 18+, with press feedback
struct TransportBarButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        #if os(tvOS)
        if #available(tvOS 26.0, *) {
            // tvOS 26+ Liquid Glass buttons
            configuration.label
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .glassEffect(
                    configuration.isPressed ? .regular.interactive() : .regular,
                    in: .capsule
                )
                .scaleEffect(configuration.isPressed ? 1.1 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
        } else {
            legacyButton(configuration: configuration)
        }
        #else
        legacyButton(configuration: configuration)
        #endif
    }

    @ViewBuilder
    private func legacyButton(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3)
            .foregroundStyle(.white)
            .padding(12)
            .background {
                #if os(tvOS)
                if #available(tvOS 18.0, *) {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .opacity(configuration.isPressed ? 1.0 : 0.6)
                        .overlay {
                            Capsule()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        }
                } else {
                    Capsule()
                        .fill(.white.opacity(configuration.isPressed ? 0.5 : 0.2))
                }
                #else
                Capsule()
                    .fill(.white.opacity(configuration.isPressed ? 0.5 : 0.2))
                #endif
            }
            .scaleEffect(configuration.isPressed ? 1.15 : 1.0)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}
