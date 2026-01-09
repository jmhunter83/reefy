//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension VideoPlayer.PlaybackControls.NavigationBar {

    struct ActionButtons: View {

        @Default(.VideoPlayer.barActionButtons)
        private var rawBarActionButtons
        @Default(.VideoPlayer.menuActionButtons)
        private var rawMenuActionButtons

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager

        /// Cached filtered buttons - computed once per body evaluation
        private var allActionButtons: [VideoPlayerActionButton] {
            // Combine bar + menu buttons, removing duplicates
            var combined = rawBarActionButtons
            for button in rawMenuActionButtons where !combined.contains(button) {
                combined.append(button)
            }

            // Filter based on current state
            var filtered = combined

            if manager.playbackItem?.audioStreams.isEmpty == true {
                filtered.removeAll { $0 == .audio }
            }

            if manager.playbackItem?.subtitleStreams.isEmpty == true {
                filtered.removeAll { $0 == .subtitles }
            }

            if manager.queue == nil {
                filtered.removeAll { $0 == .autoPlay }
                filtered.removeAll { $0 == .playNextItem }
                filtered.removeAll { $0 == .playPreviousItem }
            }

            if manager.item.isLiveStream {
                filtered.removeAll { $0 == .audio }
                filtered.removeAll { $0 == .autoPlay }
                filtered.removeAll { $0 == .playbackSpeed }
                filtered.removeAll { $0 == .playbackQuality }
                filtered.removeAll { $0 == .subtitles }
            }

            // Episodes button only for episode content
            if manager.item.type != .episode {
                filtered.removeAll { $0 == .episodes }
            }

            return filtered
        }

        @ViewBuilder
        private func view(for button: VideoPlayerActionButton) -> some View {
            switch button {
            case .aspectFill:
                AspectFill()
            case .audio:
                Audio()
            case .autoPlay:
                AutoPlay()
            case .episodes:
                Episodes()
            case .gestureLock:
                EmptyView()
            case .info:
                Info()
            case .playbackSpeed:
                PlaybackSpeed()
            case .playbackQuality:
                PlaybackQuality()
            case .playNextItem:
                PlayNextItem()
            case .playPreviousItem:
                PlayPreviousItem()
            case .subtitles:
                Subtitles()
            }
        }

        @ViewBuilder
        private func buttonGroup(_ buttons: [VideoPlayerActionButton]) -> some View {
            if buttons.isNotEmpty {
                HStack(spacing: 8) {
                    ForEach(buttons, content: view(for:))
                }
            }
        }

        var body: some View {
            // Compute once and filter for each group
            let buttons = allActionButtons

            HStack(spacing: 24) {
                // Queue group: ◀️ ▶️ 🔁
                buttonGroup(buttons.filter { [.playPreviousItem, .playNextItem, .autoPlay].contains($0) })

                // Tracks group: CC 🔊
                buttonGroup(buttons.filter { [.subtitles, .audio].contains($0) })

                // Content group: ℹ️ 📺
                buttonGroup(buttons.filter { [.info, .episodes].contains($0) })

                // Settings group: ⏱️ 📺
                buttonGroup(buttons.filter { [.playbackSpeed, .playbackQuality].contains($0) })

                // View group: ⬜
                buttonGroup(buttons.filter { [.aspectFill].contains($0) })
            }
            .labelStyle(.iconOnly)
        }
    }
}
