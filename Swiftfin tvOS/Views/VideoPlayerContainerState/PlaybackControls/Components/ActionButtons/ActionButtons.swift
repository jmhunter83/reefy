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

        /// Define button groups in display order
        private static let buttonGroups: [[VideoPlayerActionButton]] = [
            [.playPreviousItem, .playNextItem, .autoPlay], // Queue group
            [.subtitles, .audio], // Tracks group
            [.info, .episodes], // Content group
            [.playbackSpeed, .playbackQuality], // Settings group
            [.aspectFill], // View group
        ]

        /// Get the group index for a button (used for spacing)
        private func groupIndex(for button: VideoPlayerActionButton) -> Int {
            for (index, group) in Self.buttonGroups.enumerated() {
                if group.contains(button) {
                    return index
                }
            }
            return -1
        }

        var body: some View {
            let buttons = allActionButtons

            // Flat HStack with all buttons - no nesting
            HStack(spacing: 8) {
                ForEach(Array(buttons.enumerated()), id: \.element) { index, button in
                    // Add extra spacing between groups (not before first button)
                    if index > 0 {
                        let prevButton = buttons[index - 1]
                        let prevGroup = groupIndex(for: prevButton)
                        let currentGroup = groupIndex(for: button)

                        // Add spacer when transitioning between groups
                        if prevGroup != currentGroup {
                            Spacer()
                                .frame(width: 16)
                        }
                    }

                    view(for: button)
                }
            }
            .focusSection()
            .labelStyle(.iconOnly)
        }
    }
}
