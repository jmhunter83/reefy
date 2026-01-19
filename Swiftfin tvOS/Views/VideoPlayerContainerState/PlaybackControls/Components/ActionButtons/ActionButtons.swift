//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import os.log
import SwiftUI
import VLCUI

private let focusLog = Logger(subsystem: "org.jellyfin.swiftfin", category: "ActionButtonsFocus")
private let audioDebugLog = Logger(subsystem: "org.jellyfin.swiftfin", category: "AudioButtonDebug")

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
        @EnvironmentObject
        private var focusGuide: FocusGuide

        @FocusState
        private var focusedButton: VideoPlayerActionButton?

        /// Cached filtered buttons - computed once per body evaluation
        private var allActionButtons: [VideoPlayerActionButton] {
            // Debug: Log audio stream state at filter entry
            let audioStreamsCount = manager.playbackItem?.audioStreams.count ?? -1
            let audioStreamsEmpty = manager.playbackItem?.audioStreams.isEmpty
            audioDebugLog.debug("🔊 FILTER: audioStreams.count=\(audioStreamsCount) isEmpty=\(String(describing: audioStreamsEmpty))")

            // Combine bar + menu buttons, removing duplicates
            var combined = rawBarActionButtons
            for button in rawMenuActionButtons where !combined.contains(button) {
                combined.append(button)
            }

            // Build set of buttons to exclude based on current state
            // Exclude audio, subtitles (moved to side), info, aspectFill, skip intro
            var excluded: Set<VideoPlayerActionButton> = [.audio, .subtitles, .info, .aspectFill, .skipIntro]

            if manager.queue == nil {
                excluded.formUnion([.autoPlay, .playNextItem, .playPreviousItem])
            }

            if manager.item.isLiveStream {
                excluded.formUnion([.audio, .autoPlay, .playbackSpeed, .playbackQuality, .subtitles])
            }

            if manager.item.type != .episode {
                excluded.insert(.episodes)
            }

            let finalButtons = combined.filter { !excluded.contains($0) }
            audioDebugLog.debug("🔊 FILTER: excluded=\(excluded.map(\.rawValue)) final=\(finalButtons.map(\.rawValue))")
            return finalButtons
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
            case .skipIntro:
                SkipIntro()
            }
        }

        private func defaultFocusButton(from buttons: [VideoPlayerActionButton]) -> VideoPlayerActionButton? {
            buttons.contains(.subtitles) ? .subtitles : buttons.first
        }

        var body: some View {
            let buttons = allActionButtons

            HStack(spacing: 16) {
                ForEach(buttons, id: \.self) { button in
                    view(for: button)
                        .focused($focusedButton, equals: button)
                }
            }
            .labelStyle(.iconOnly)
            .focusGuide(
                focusGuide,
                tag: "actionButtons",
                onContentFocus: {
                    // Only set focus when NOT scrubbing to prevent focus theft during timeline scrubbing
                    guard !containerState.isScrubbing else { return }
                    focusedButton = defaultFocusButton(from: buttons)
                },
                bottom: "playbackProgress"
            )
            .onChange(of: focusedButton) { oldValue, newValue in
                // Machine-friendly log: event|old|new|buttonCount
                focusLog.debug("FOCUS_CHANGE|\(oldValue?.rawValue ?? "nil")|\(newValue?.rawValue ?? "nil")|\(buttons.count)")

                if newValue != nil {
                    containerState.timer.poke()
                }
                containerState.isActionButtonsFocused = (newValue != nil)
            }
        }
    }
}
