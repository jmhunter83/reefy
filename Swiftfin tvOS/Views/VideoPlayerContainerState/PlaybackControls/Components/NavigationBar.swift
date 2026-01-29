//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension VideoPlayer.PlaybackControls {

    /// Floating info pill for top-left of video player overlay
    /// Shows title metadata with Liquid Glass background
    struct NavigationBar: View {

        @EnvironmentObject
        private var manager: MediaPlayerManager

        private var item: BaseItemDto {
            manager.item
        }

        /// For episodes: series name. For movies: nil
        private var seriesName: String? {
            item.seriesName
        }

        /// Year from premiere date or production year
        private var year: String? {
            if let premiereYear = item.premiereDate?.formatted(.dateTime.year()) {
                return premiereYear
            } else if let productionYear = item.productionYear {
                return String(productionYear)
            }
            return nil
        }

        /// Season/Episode label (e.g., "S01E05")
        private var seasonEpisodeLabel: String? {
            guard item.type == .episode,
                  let seasonIndex = item.parentIndexNumber,
                  let episodeIndex = item.indexNumber
            else { return nil }
            return String(format: "S%02dE%02d", seasonIndex, episodeIndex)
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                // Line 1: Series name + Year (episodes) OR Title + Year (movies)
                HStack {
                    Text(seriesName ?? item.displayTitle)
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.85))

                    Spacer()

                    if let year {
                        Text(year)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

                // Line 2: S##E## · Episode Title (episodes) OR subtitle/tagline (movies)
                if item.type == .episode, let episodeLabel = seasonEpisodeLabel {
                    Text("\(episodeLabel) · \(item.displayTitle)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                } else if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                } else {
                    Text(item.displayTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 20)
            .frame(maxWidth: 600, alignment: .leading)
            .background {
                TransportBarBackground()
            }
        }
    }
}
