//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.PlaybackControls.NavigationBar.ActionButtons {

    struct Episodes: View {

        /// Focus state passed from parent ActionButtons view
        let isFocused: Bool

        @Environment(\.isInMenu)
        private var isInMenu

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager

        /// Episodes supplement is the queue for series content
        private var episodesSupplement: (any MediaPlayerSupplement)? {
            manager.supplements.first { $0 is EpisodeMediaPlayerQueue }
        }

        /// Only show for episode content
        private var isEpisodeContent: Bool {
            manager.item.type == .episode
        }

        var body: some View {
            if isEpisodeContent {
                if isInMenu {
                    Button {
                        if let supplement = episodesSupplement {
                            containerState.select(supplement: supplement)
                        }
                    } label: {
                        Label(L10n.episodes, systemImage: "tv")
                    }
                } else {
                    TransportBarButton(isFocused: isFocused) {
                        if let supplement = episodesSupplement {
                            containerState.select(supplement: supplement)
                        }
                    } label: {
                        Image(systemName: "tv")
                    }
                }
            }
        }
    }
}
