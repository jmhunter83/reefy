//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct TrackInfoView: View {

    @EnvironmentObject
    private var manager: MediaPlayerManager

    private var trackTitle: String {
        manager.item.displayTitle
    }

    private var artistName: String? {
        // Try albumArtist first, then artists array
        manager.item.albumArtist ?? manager.item.artists?.first
    }

    private var albumName: String? {
        manager.item.album
    }

    var body: some View {
        VStack(spacing: 8) {
            // Track title
            Text(trackTitle)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            // Artist
            if let artistName {
                Text(artistName)
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(1)
            }

            // Album
            if let albumName {
                Text(albumName)
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 60)
    }
}
