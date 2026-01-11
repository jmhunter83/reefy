//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.PlaybackControls.NavigationBar.ActionButtons {

    struct Subtitles: View {

        /// Focus state passed from parent ActionButtons view
        let isFocused: Bool

        @Environment(\.isInMenu)
        private var isInMenu

        @EnvironmentObject
        private var manager: MediaPlayerManager

        @State
        private var selectedSubtitleStreamIndex: Int?

        private var systemImage: String {
            if selectedSubtitleStreamIndex == nil {
                "captions.bubble"
            } else {
                "captions.bubble.fill"
            }
        }

        @ViewBuilder
        private func content(playbackItem: MediaPlayerItem) -> some View {
            // "Off" option at the top with visual distinction
            Button {
                playbackItem.selectedSubtitleStreamIndex = -1
            } label: {
                if selectedSubtitleStreamIndex == -1 || selectedSubtitleStreamIndex == nil {
                    Label(L10n.none, systemImage: "checkmark")
                } else {
                    Label(L10n.none, systemImage: "xmark.circle")
                }
            }

            Divider()

            // Subtitle streams with codec info
            ForEach(playbackItem.subtitleStreams, id: \.index) { stream in
                Button {
                    playbackItem.selectedSubtitleStreamIndex = stream.index ?? -1
                } label: {
                    if selectedSubtitleStreamIndex == stream.index {
                        Label(stream.formattedSubtitleTitle, systemImage: "checkmark")
                    } else {
                        Text(stream.formattedSubtitleTitle)
                    }
                }
            }
        }

        var body: some View {
            if let playbackItem = manager.playbackItem {
                if isInMenu {
                    // Inside overflow menu - use standard Menu
                    Menu(
                        L10n.subtitles,
                        systemImage: systemImage
                    ) {
                        content(playbackItem: playbackItem)
                    }
                    .assign(playbackItem.$selectedSubtitleStreamIndex, to: $selectedSubtitleStreamIndex)
                } else {
                    // In bar - use native focus wrapper
                    TransportBarMenu(L10n.subtitles, isFocused: isFocused) {
                        Image(systemName: systemImage)
                    } content: {
                        Section(L10n.subtitles) {
                            content(playbackItem: playbackItem)
                        }
                    }
                    .assign(playbackItem.$selectedSubtitleStreamIndex, to: $selectedSubtitleStreamIndex)
                }
            }
        }
    }
}
