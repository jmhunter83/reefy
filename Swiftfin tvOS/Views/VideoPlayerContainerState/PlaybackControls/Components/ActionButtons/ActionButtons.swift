//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Logging
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

        private let logger = Logger.swiftfin()

        private func filteredActionButtons(_ rawButtons: [VideoPlayerActionButton]) -> [VideoPlayerActionButton] {
            var filteredButtons = rawButtons

            // DEBUG: Log audio stream state
            let audioCount = manager.playbackItem?.audioStreams.count ?? -1
            let subtitleCount = manager.playbackItem?.subtitleStreams.count ?? -1
            let isLive = manager.item.isLiveStream
            logger.debug(
                "ActionButtons: audio=\(audioCount), subs=\(subtitleCount), live=\(isLive)"
            )

            if manager.playbackItem?.audioStreams.isEmpty == true {
                logger.debug("Filtering out audio - no streams")
                filteredButtons.removeAll { $0 == .audio }
            }

            if manager.playbackItem?.subtitleStreams.isEmpty == true {
                filteredButtons.removeAll { $0 == .subtitles }
            }

            if manager.queue == nil {
                filteredButtons.removeAll { $0 == .autoPlay }
                filteredButtons.removeAll { $0 == .playNextItem }
                filteredButtons.removeAll { $0 == .playPreviousItem }
            }

            if manager.item.isLiveStream {
                filteredButtons.removeAll { $0 == .audio }
                filteredButtons.removeAll { $0 == .autoPlay }
                filteredButtons.removeAll { $0 == .playbackSpeed }
                filteredButtons.removeAll { $0 == .playbackQuality }
                filteredButtons.removeAll { $0 == .subtitles }
            }

            // Episodes button only for episode content
            if manager.item.type != .episode {
                filteredButtons.removeAll { $0 == .episodes }
            }

            return filteredButtons
        }

        /// All action buttons shown directly in bar (no overflow menu)
        private var allActionButtons: [VideoPlayerActionButton] {
            // Combine bar + menu buttons, removing duplicates
            var combined = rawBarActionButtons
            for button in rawMenuActionButtons where !combined.contains(button) {
                combined.append(button)
            }
            return filteredActionButtons(combined)
        }

        // MARK: - Button Groups

        /// Queue control buttons (previous, next, autoplay)
        private var queueButtons: [VideoPlayerActionButton] {
            allActionButtons.filter { [.playPreviousItem, .playNextItem, .autoPlay].contains($0) }
        }

        /// Track selection buttons (subtitles, audio)
        private var trackButtons: [VideoPlayerActionButton] {
            allActionButtons.filter { [.subtitles, .audio].contains($0) }
        }

        /// Playback settings buttons (speed, quality)
        private var settingsButtons: [VideoPlayerActionButton] {
            allActionButtons.filter { [.playbackSpeed, .playbackQuality].contains($0) }
        }

        /// Content buttons (info, episodes)
        private var contentButtons: [VideoPlayerActionButton] {
            allActionButtons.filter { [.info, .episodes].contains($0) }
        }

        /// View buttons (aspect fill)
        private var viewButtons: [VideoPlayerActionButton] {
            allActionButtons.filter { [.aspectFill].contains($0) }
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
            HStack(spacing: 24) {
                // Queue group: ◀️ ▶️ 🔁
                buttonGroup(queueButtons)

                // Tracks group: CC 🔊
                buttonGroup(trackButtons)

                // Content group: ℹ️ 📺
                buttonGroup(contentButtons)

                // Settings group: ⏱️ 📺
                buttonGroup(settingsButtons)

                // View group: ⬜
                buttonGroup(viewButtons)
            }
            .labelStyle(.iconOnly)
        }
    }
}
