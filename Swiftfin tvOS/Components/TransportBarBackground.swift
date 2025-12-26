//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

/// Native tvOS transport bar glass background
/// Uses Liquid Glass effect on tvOS 18+ with vibrancy fallback for older versions
struct TransportBarBackground: View {

    var body: some View {
        #if os(tvOS)
        if #available(tvOS 18.0, *) {
            // tvOS 18+ enhanced glass effect
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
        } else {
            // tvOS 17 fallback
            BlurView(style: .prominent)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                }
        }
        #else
        EmptyView()
        #endif
    }
}
