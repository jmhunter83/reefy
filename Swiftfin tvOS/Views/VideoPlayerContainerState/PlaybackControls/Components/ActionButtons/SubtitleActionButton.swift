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

        var focusBinding: FocusState<VideoPlayerActionButton?>.Binding
        let buttonType: VideoPlayerActionButton

        @Environment(\.isInMenu)
        private var isInMenu

        @EnvironmentObject
        private var manager: MediaPlayerManager

        @State
        private var selectedSubtitleStreamIndex: Int?

        private var systemImage: String {
            selectedSubtitleStreamIndex == nil ? "captions.bubble" : "captions.bubble.fill"
        }

        private var isSubtitlesOff: Bool {
            selectedSubtitleStreamIndex == -1 || selectedSubtitleStreamIndex == nil
        }

        @ViewBuilder
        private func content(playbackItem: MediaPlayerItem) -> some View {
            Button {
                playbackItem.selectedSubtitleStreamIndex = -1
            } label: {
                if isSubtitlesOff {
                    Label(L10n.none, systemImage: "checkmark")
                } else {
                    Label(L10n.none, systemImage: "xmark.circle")
                }
            }

            Divider()

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
                    Menu(L10n.subtitles, systemImage: systemImage) {
                        content(playbackItem: playbackItem)
                    }
                    .assign(playbackItem.$selectedSubtitleStreamIndex, to: $selectedSubtitleStreamIndex)
                } else {
                    TransportBarMenu(
                        L10n.subtitles,
                        focusBinding: focusBinding,
                        buttonType: buttonType
                    ) {
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
