//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension VideoPlayer.PlaybackControls.NavigationBar.ActionButtons {

    struct PlaybackQuality: View {

        /// Focus state passed from parent ActionButtons view
        let isFocused: Bool

        @Environment(\.isInMenu)
        private var isInMenu

        @Default(.VideoPlayer.Playback.appMaximumBitrate)
        private var currentBitrate

        private func isCurrentBitrate(_ bitrate: PlaybackBitrate) -> Bool {
            currentBitrate == bitrate
        }

        @ViewBuilder
        private var content: some View {
            ForEach(PlaybackBitrate.allCases, id: \.self) { bitrate in
                Button {
                    currentBitrate = bitrate
                } label: {
                    if isCurrentBitrate(bitrate) {
                        Label(bitrate.displayTitle, systemImage: "checkmark")
                    } else {
                        Text(bitrate.displayTitle)
                    }
                }
            }
        }

        var body: some View {
            if isInMenu {
                // Inside overflow menu - use standard Menu
                Menu(
                    L10n.playbackQuality,
                    systemImage: "tv.circle"
                ) {
                    content
                }
            } else {
                // In bar - use native focus wrapper
                TransportBarMenu(L10n.playbackQuality, isFocused: isFocused) {
                    Image(systemName: "tv.circle")
                } content: {
                    Section(L10n.playbackQuality) {
                        content
                    }
                }
            }
        }
    }
}
