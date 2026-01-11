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

        // MARK: - Single Focus State for All Buttons

        /// Single source of truth for button focus - enables horizontal navigation
        /// per WWDC21/23 recommendations. Each button is visual-only; parent manages focus.
        @FocusState
        private var focusedButton: VideoPlayerActionButton?

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

            // Remove non-functional buttons on tvOS
            filtered.removeAll { $0 == .info }
            filtered.removeAll { $0 == .aspectFill }

            return filtered
        }

        /// Creates the view for a button, passing the focus state
        @ViewBuilder
        private func view(for button: VideoPlayerActionButton, isFocused: Bool) -> some View {
            switch button {
            case .aspectFill:
                AspectFill(isFocused: isFocused)
            case .audio:
                Audio(isFocused: isFocused)
            case .autoPlay:
                AutoPlay(isFocused: isFocused)
            case .episodes:
                Episodes(isFocused: isFocused)
            case .gestureLock:
                EmptyView()
            case .info:
                Info(isFocused: isFocused)
            case .playbackSpeed:
                PlaybackSpeed(isFocused: isFocused)
            case .playbackQuality:
                PlaybackQuality(isFocused: isFocused)
            case .playNextItem:
                PlayNextItem(isFocused: isFocused)
            case .playPreviousItem:
                PlayPreviousItem(isFocused: isFocused)
            case .subtitles:
                Subtitles(isFocused: isFocused)
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

        /// Determine default focus button - subtitles is universal across movies/shows
        private func defaultFocusButton(from buttons: [VideoPlayerActionButton]) -> VideoPlayerActionButton? {
            // Prefer subtitles as default (universal for movies/shows)
            if buttons.contains(.subtitles) {
                return .subtitles
            }
            // Fall back to first available button
            return buttons.first
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

                    // Button with focus binding - enables horizontal navigation
                    view(for: button, isFocused: focusedButton == button)
                        .focused($focusedButton, equals: button)
                }
            }
            .labelStyle(.iconOnly)
            // Focus section enables directional navigation within this container
            .focusSection()
            // Set default focus to subtitles button (universal across content types)
            .defaultFocus($focusedButton, defaultFocusButton(from: buttons))
            // Track when action buttons gain/lose focus
            .onChange(of: focusedButton) { _, newValue in
                if newValue != nil {
                    // Poke timer when focus moves between buttons
                    containerState.timer.poke()
                }
                // Update container state for arrow key handling
                containerState.isActionButtonsFocused = (newValue != nil)
            }
        }
    }
}
