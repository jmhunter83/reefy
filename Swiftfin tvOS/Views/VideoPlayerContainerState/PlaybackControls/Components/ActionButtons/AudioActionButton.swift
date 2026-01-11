//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.PlaybackControls.NavigationBar.ActionButtons {

    struct Audio: View {

        /// Focus state passed from parent ActionButtons view
        let isFocused: Bool

        @Environment(\.isInMenu)
        private var isInMenu

        @EnvironmentObject
        private var manager: MediaPlayerManager

        @State
        private var selectedAudioStreamIndex: Int?

        private var systemImage: String {
            if selectedAudioStreamIndex == nil {
                "speaker.wave.2"
            } else {
                "speaker.wave.2.fill"
            }
        }

        @ViewBuilder
        private func content(playbackItem: MediaPlayerItem) -> some View {
            ForEach(playbackItem.audioStreams, id: \.index) { stream in
                Button {
                    playbackItem.selectedAudioStreamIndex = stream.index ?? -1
                } label: {
                    if selectedAudioStreamIndex == stream.index {
                        Label(stream.formattedAudioTitle, systemImage: "checkmark")
                    } else {
                        Text(stream.formattedAudioTitle)
                    }
                }
            }
        }

        var body: some View {
            if let playbackItem = manager.playbackItem {
                if isInMenu {
                    // Inside overflow menu - use standard Menu
                    Menu(
                        L10n.audio,
                        systemImage: systemImage
                    ) {
                        content(playbackItem: playbackItem)
                    }
                    .assign(playbackItem.$selectedAudioStreamIndex, to: $selectedAudioStreamIndex)
                } else {
                    // In bar - use native focus wrapper
                    TransportBarMenu(L10n.audio, isFocused: isFocused) {
                        Image(systemName: systemImage)
                    } content: {
                        Section(L10n.audio) {
                            content(playbackItem: playbackItem)
                        }
                    }
                    .assign(playbackItem.$selectedAudioStreamIndex, to: $selectedAudioStreamIndex)
                }
            }
        }
    }
}
