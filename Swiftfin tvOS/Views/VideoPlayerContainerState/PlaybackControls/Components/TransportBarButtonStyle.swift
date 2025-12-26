//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

/// Button style for transport bar action buttons
/// Uses glass effect on tvOS 18+ with focus states
struct TransportBarButtonStyle: ButtonStyle {

    @Environment(\.isFocused)
    private var isFocused

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3)
            .foregroundStyle(.white)
            .padding(12)
            .background {
                #if os(tvOS)
                if isFocused {
                    if #available(tvOS 18.0, *) {
                        Capsule()
                            .fill(.regularMaterial)
                            .opacity(0.8)
                    } else {
                        Capsule()
                            .fill(.white.opacity(0.3))
                    }
                }
                #else
                if isFocused {
                    Capsule()
                        .fill(.white.opacity(0.3))
                }
                #endif
            }
            .scaleEffect(isFocused ? 1.1 : 1.0)
            .animation(.spring(response: 0.3), value: isFocused)
    }
}
