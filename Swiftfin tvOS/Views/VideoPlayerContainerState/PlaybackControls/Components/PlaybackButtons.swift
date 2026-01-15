//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

// MARK: - Center Playback Buttons

/// Large centered play/pause and jump buttons for tvOS video player.
/// Uses modern Liquid Glass design for tvOS 26+ with compact, refined buttons.
extension VideoPlayer.PlaybackControls {

    struct PlaybackButtons: View {

        @Default(.VideoPlayer.jumpBackwardInterval)
        private var jumpBackwardInterval
        @Default(.VideoPlayer.jumpForwardInterval)
        private var jumpForwardInterval

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager

        @FocusState
        private var focusedButton: ButtonType?

        private enum ButtonType: Hashable {
            case jumpBackward
            case playPause
            case jumpForward
        }

        private var shouldShowJumpButtons: Bool {
            !manager.item.isLiveStream
        }

        // MARK: - Play/Pause Button

        @ViewBuilder
        private var playPauseButton: some View {
            Button {
                switch manager.playbackRequestStatus {
                case .playing:
                    manager.setPlaybackRequestStatus(status: .paused)
                case .paused:
                    manager.setPlaybackRequestStatus(status: .playing)
                }
            } label: {
                Group {
                    switch manager.playbackRequestStatus {
                    case .playing:
                        Image(systemName: "pause.fill")
                    case .paused:
                        Image(systemName: "play.fill")
                    }
                }
                .font(.system(size: 52, weight: .bold))
                .frame(width: 110, height: 110)
                .background {
                    playbackButtonBackground(isFocused: focusedButton == .playPause)
                }
            }
            .buttonStyle(.plain)
            .focused($focusedButton, equals: .playPause)
            .scaleEffect(focusedButton == .playPause ? 1.08 : 1.0)
            .shadow(
                color: focusedButton == .playPause ? .black.opacity(0.2) : .clear,
                radius: focusedButton == .playPause ? 12 : 0,
                y: focusedButton == .playPause ? 8 : 0
            )
            .animation(.spring(duration: 0.2), value: focusedButton)
        }

        // MARK: - Jump Backward Button

        @ViewBuilder
        private var jumpBackwardButton: some View {
            Button {
                manager.proxy?.jumpBackward(jumpBackwardInterval.rawValue)
            } label: {
                Image(systemName: jumpBackwardInterval.secondarySystemImage)
                    .font(.system(size: 32, weight: .semibold))
                    .frame(width: 72, height: 72)
                    .background {
                        playbackButtonBackground(isFocused: focusedButton == .jumpBackward)
                    }
            }
            .buttonStyle(.plain)
            .focused($focusedButton, equals: .jumpBackward)
            .scaleEffect(focusedButton == .jumpBackward ? 1.05 : 1.0)
            .shadow(
                color: focusedButton == .jumpBackward ? .black.opacity(0.2) : .clear,
                radius: focusedButton == .jumpBackward ? 10 : 0,
                y: focusedButton == .jumpBackward ? 6 : 0
            )
            .animation(.spring(duration: 0.2), value: focusedButton)
        }

        // MARK: - Jump Forward Button

        @ViewBuilder
        private var jumpForwardButton: some View {
            Button {
                manager.proxy?.jumpForward(jumpForwardInterval.rawValue)
            } label: {
                Image(systemName: jumpForwardInterval.systemImage)
                    .font(.system(size: 32, weight: .semibold))
                    .frame(width: 72, height: 72)
                    .background {
                        playbackButtonBackground(isFocused: focusedButton == .jumpForward)
                    }
            }
            .buttonStyle(.plain)
            .focused($focusedButton, equals: .jumpForward)
            .scaleEffect(focusedButton == .jumpForward ? 1.05 : 1.0)
            .shadow(
                color: focusedButton == .jumpForward ? .black.opacity(0.2) : .clear,
                radius: focusedButton == .jumpForward ? 10 : 0,
                y: focusedButton == .jumpForward ? 6 : 0
            )
            .animation(.spring(duration: 0.2), value: focusedButton)
        }

        // MARK: - Button Background

        @ViewBuilder
        private func playbackButtonBackground(isFocused: Bool) -> some View {
            if #available(tvOS 26.0, *) {
                Circle()
                    .fill(.clear)
                    .glassEffect(
                        isFocused
                            ? .regular.tint(.white.opacity(0.3))
                            : .regular
                    )
            } else {
                Circle()
                    .fill(
                        isFocused
                            ? Color.white.opacity(0.4)
                            : Color.white.opacity(0.2)
                    )
            }
        }

        // MARK: - Body

        var body: some View {
            HStack(spacing: 50) {
                if shouldShowJumpButtons {
                    jumpBackwardButton
                }

                playPauseButton

                if shouldShowJumpButtons {
                    jumpForwardButton
                }
            }
            .foregroundStyle(.white)
        }
    }
}
