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

        @FocusState
        private var focusedButton: VideoPlayerActionButton?

        /// Cached filtered buttons - computed once per body evaluation
        private var allActionButtons: [VideoPlayerActionButton] {
            // Combine bar + menu buttons, removing duplicates
            var combined = rawBarActionButtons
            for button in rawMenuActionButtons where !combined.contains(button) {
                combined.append(button)
            }

            // Build set of buttons to exclude based on current state
            var excluded: Set<VideoPlayerActionButton> = [.info, .aspectFill]

            if manager.playbackItem?.audioStreams.isEmpty == true {
                excluded.insert(.audio)
            }

            if manager.playbackItem?.subtitleStreams.isEmpty == true {
                excluded.insert(.subtitles)
            }

            if manager.queue == nil {
                excluded.formUnion([.autoPlay, .playNextItem, .playPreviousItem])
            }

            if manager.item.isLiveStream {
                excluded.formUnion([.audio, .autoPlay, .playbackSpeed, .playbackQuality, .subtitles])
            }

            if manager.item.type != .episode {
                excluded.insert(.episodes)
            }

            return combined.filter { !excluded.contains($0) }
        }

        @ViewBuilder
        private func view(for button: VideoPlayerActionButton) -> some View {
            switch button {
            case .aspectFill:
                AspectFill(focusBinding: $focusedButton, buttonType: button)
            case .audio:
                Audio(focusBinding: $focusedButton, buttonType: button)
            case .autoPlay:
                AutoPlay(focusBinding: $focusedButton, buttonType: button)
            case .episodes:
                Episodes(focusBinding: $focusedButton, buttonType: button)
            case .gestureLock:
                EmptyView()
            case .info:
                Info(focusBinding: $focusedButton, buttonType: button)
            case .playbackSpeed:
                PlaybackSpeed(focusBinding: $focusedButton, buttonType: button)
            case .playbackQuality:
                PlaybackQuality(focusBinding: $focusedButton, buttonType: button)
            case .playNextItem:
                PlayNextItem(focusBinding: $focusedButton, buttonType: button)
            case .playPreviousItem:
                PlayPreviousItem(focusBinding: $focusedButton, buttonType: button)
            case .subtitles:
                Subtitles(focusBinding: $focusedButton, buttonType: button)
            }
        }

        private func defaultFocusButton(from buttons: [VideoPlayerActionButton]) -> VideoPlayerActionButton? {
            buttons.contains(.subtitles) ? .subtitles : buttons.first
        }

        var body: some View {
            let buttons = allActionButtons

            HStack(spacing: 24) {
                ForEach(buttons, id: \.self) { button in
                    view(for: button)
                }
            }
            .focusSection()
            .labelStyle(.iconOnly)
            .defaultFocus($focusedButton, defaultFocusButton(from: buttons))
            .onChange(of: focusedButton) { oldValue, newValue in
                if newValue != nil {
                    containerState.timer.poke()
                }
                containerState.isActionButtonsFocused = (newValue != nil)

                guard let oldValue, let newValue else { return }

                let oldIndex = buttons.firstIndex(of: oldValue)
                let newIndex = buttons.firstIndex(of: newValue)

                if let oldIdx = oldIndex, let newIdx = newIndex {
                    if oldIdx == 0 && newIdx == buttons.count - 1 {
                        focusedButton = buttons.first
                    } else if oldIdx == buttons.count - 1 && newIdx == 0 {
                        focusedButton = buttons.last
                    }
                }
            }
        }
    }
}
