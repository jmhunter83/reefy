//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// MARK: - Album Art Background (Blurred)

struct AlbumArtBackground: View {

    @EnvironmentObject
    private var manager: MediaPlayerManager

    var body: some View {
        ZStack {
            Color.black

            ImageView(manager.item.imageSource(.primary, maxWidth: 800))
                .aspectRatio(contentMode: .fill)
                .blur(radius: 60)
                .opacity(0.6)
                .scaleEffect(1.2) // Prevent blur edge artifacts
        }
        .ignoresSafeArea()
    }
}

// MARK: - Album Art View (Sharp, Centered)

struct AlbumArtView: View {

    @EnvironmentObject
    private var manager: MediaPlayerManager

    var body: some View {
        ImageView(manager.item.imageSource(.primary, maxWidth: 400))
            .aspectRatio(contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(.white.opacity(0.1), lineWidth: 1)
            }
    }
}
