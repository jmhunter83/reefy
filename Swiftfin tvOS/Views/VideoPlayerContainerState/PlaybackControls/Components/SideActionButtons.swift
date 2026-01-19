//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI
import VLCUI

extension VideoPlayer.PlaybackControls {

    /// Right-side vertical stack containing Audio and Subtitles buttons.
    /// Positioned at 25% from bottom, above the transport bar.
    struct SideActionButtons: View {

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager
        @EnvironmentObject
        private var focusGuide: FocusGuide

        @FocusState
        private var focusedButton: SideButton?

        enum SideButton: Hashable {
            case audio
            case subtitles
        }

        var body: some View {
            GeometryReader { geometry in
                // Inner button stack with glass backdrop (sized to content only)
                VStack(spacing: 16) {
                    // Audio picker (top)
                    if let playbackItem = manager.playbackItem {
                        InlineStreamPicker(
                            title: L10n.audio,
                            systemImage: audioIcon,
                            streams: playbackItem.audioStreams,
                            selectedIndex: playbackItem.selectedAudioStreamIndex,
                            onSelect: { stream in
                                playbackItem.selectedAudioStreamIndex = stream.index ?? -1
                            }
                        )
                        .focused($focusedButton, equals: .audio)
                    }

                    // Subtitles picker (bottom)
                    if let playbackItem = manager.playbackItem,
                       !playbackItem.subtitleStreams.isEmpty
                    {
                        InlineStreamPicker(
                            title: L10n.subtitles,
                            systemImage: subtitleIcon,
                            streams: playbackItem.subtitleStreams,
                            selectedIndex: playbackItem.selectedSubtitleStreamIndex,
                            onSelect: { stream in
                                playbackItem.selectedSubtitleStreamIndex = stream.index ?? -1
                            }
                        )
                        .focused($focusedButton, equals: .subtitles)
                    }
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 24)
                .background { TransportBarBackground() }
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.4), radius: 16)
                // Position at 25% from bottom (75% from top), right edge
                .position(
                    x: geometry.size.width - 150,
                    y: geometry.size.height * 0.75
                )
            }
            .focusGuide(focusGuide, tag: "sideButtons", bottom: "transportBar")
            .isVisible(isScrubbing || isPresentingOverlay)
        }

        private var isScrubbing: Bool {
            containerState.isScrubbing
        }

        private var isPresentingOverlay: Bool {
            containerState.isPresentingOverlay
        }

        private var audioIcon: String {
            "speaker.wave.2"
        }

        private var subtitleIcon: String {
            if let index = manager.playbackItem?.selectedSubtitleStreamIndex,
               index != -1
            {
                return "captions.bubble.fill"
            }
            return "captions.bubble"
        }
    }
}
