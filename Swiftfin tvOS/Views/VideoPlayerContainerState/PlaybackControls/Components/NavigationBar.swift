//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.PlaybackControls {

    struct NavigationBar: View {

        @EnvironmentObject
        private var manager: MediaPlayerManager

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                // For episodes: Show series name, S#:E#, episode name
                if manager.item.type == .episode {
                    if let seriesName = manager.item.seriesName {
                        Text(seriesName)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }

                    if let seasonEpisode = manager.item.subtitle {
                        Text(seasonEpisode)
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.9))
                    }

                    Text(manager.item.displayTitle)
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.8))
                } else {
                    // For non-episodes: Show subtitle (if any) then title
                    if let subtitle = manager.item.subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                    }

                    Text(manager.item.displayTitle)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}
