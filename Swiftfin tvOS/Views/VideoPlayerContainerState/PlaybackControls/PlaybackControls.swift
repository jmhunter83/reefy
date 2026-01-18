//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import PreferencesView
import SwiftUI
import VLCUI

extension VideoPlayer {

    struct PlaybackControls: View {

        // since this view ignores safe area, it must
        // get safe area insets from parent views
        @Environment(\.safeAreaInsets)
        private var safeAreaInsets

        @Default(.VideoPlayer.jumpBackwardInterval)
        private var jumpBackwardInterval
        @Default(.VideoPlayer.jumpForwardInterval)
        private var jumpForwardInterval

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var focusGuide: FocusGuide
        @EnvironmentObject
        private var manager: MediaPlayerManager

        @OnPressEvent
        private var onPressEvent

        @Router
        private var router

        @State
        private var contentSize: CGSize = .zero
        @State
        private var effectiveSafeArea: EdgeInsets = .zero

        private var isPresentingOverlay: Bool {
            containerState.isPresentingOverlay
        }

        private var isPresentingSupplement: Bool {
            containerState.isPresentingSupplement
        }

        private var isScrubbing: Bool {
            containerState.isScrubbing
        }

        @ViewBuilder
        private var titleOverlay: some View {
            if !isPresentingSupplement {
                VStack(alignment: .leading, spacing: 8) {
                    if manager.item.type == .episode {
                        // Episode: Show S#E# • Series Name • Episode Title • Year
                        if let seasonEpisodeLabel = manager.item.seasonEpisodeLabel {
                            Text(seasonEpisodeLabel)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white.opacity(0.9))
                                .shadow(color: .black.opacity(0.5), radius: 8)
                        }

                        if let seriesName = manager.item.seriesName {
                            Text(seriesName)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.5), radius: 8)
                        }

                        Text(manager.item.displayTitle)
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.8))
                            .shadow(color: .black.opacity(0.5), radius: 8)

                        if let year = manager.item.premiereDateYear {
                            Text(year)
                                .font(.callout)
                                .foregroundStyle(.white.opacity(0.7))
                                .shadow(color: .black.opacity(0.5), radius: 8)
                        }
                    } else {
                        // Non-episode: Show Title • Year
                        Text(manager.item.displayTitle)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.5), radius: 8)

                        if let year = manager.item.premiereDateYear {
                            Text(year)
                                .font(.title3)
                                .foregroundStyle(.white.opacity(0.8))
                                .shadow(color: .black.opacity(0.5), radius: 8)
                        }
                    }
                }
                .padding(.leading, 80)
                .padding(.top, 60)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .isVisible(isScrubbing || isPresentingOverlay)
            }
        }

        // Center playback buttons removed - using remote control for play/pause and skip

        @ViewBuilder
        private var transportBar: some View {
            if !isPresentingSupplement {
                VStack(spacing: 16) {
                    // Action buttons row - right aligned, small icons
                    HStack {
                        Spacer()

                        NavigationBar.ActionButtons()
                    }
                    .focusGuide(focusGuide, tag: "actionButtons", bottom: "playbackProgress")

                    // Progress bar with time labels
                    PlaybackProgress()
                        .focusGuide(focusGuide, tag: "playbackProgress", top: "actionButtons")
                }
                .padding(.horizontal, 60)
                .padding(.vertical, 30)
                .background {
                    TransportBarBackground()
                }
            }
        }

        // MARK: - Skip Indicator

        @ViewBuilder
        private var skipIndicator: some View {
            if let text = containerState.skipIndicatorText {
                Text(text)
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 10)
                    .transition(.scale.combined(with: .opacity))
            }
        }

        var body: some View {
            GeometryReader { geometry in
                ZStack {
                    // Title in top-left
                    titleOverlay

                    // Skip indicator in center
                    skipIndicator
                        .animation(.easeOut(duration: 0.2), value: containerState.skipIndicatorText)

                    // Transport bar in bottom 15%
                    VStack {
                        Spacer()
                            .frame(minHeight: geometry.size.height * 0.85)

                        transportBar
                            .padding(.horizontal, 40)
                            .padding(.bottom, 60)
                            .opacity(isScrubbing || isPresentingOverlay ? 1 : 0)
                            .disabled(!(isScrubbing || isPresentingOverlay))
                    }
                }
            }
            .animation(.linear(duration: 0.1), value: isScrubbing)
            .animation(.bouncy(duration: 0.4), value: isPresentingSupplement)
            .animation(.bouncy(duration: 0.25), value: isPresentingOverlay)
            .onDisappear {
                // Clean up any active scrubbing timers when view disappears
                containerState.cleanupScrubbing()
            }
            .onChange(of: isPresentingOverlay) { _, isPresenting in
                if isPresenting {
                    // Focus action buttons when overlay appears
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        focusGuide.transition(to: "actionButtons")
                    }
                } else {
                    // Reset focus tracking when overlay hides
                    containerState.isActionButtonsFocused = false
                }
            }
            .onReceive(onPressEvent) { press in
                switch press {
                case (.playPause, .began):
                    // Show overlay and toggle play/pause
                    if !containerState.isPresentingOverlay {
                        withAnimation(.linear(duration: 0.25)) {
                            containerState.isPresentingOverlay = true
                        }
                    } else {
                        containerState.timer.poke()
                    }
                    manager.togglePlayPause()

                case (.leftArrow, .began):
                    // Skip backward press began (only when not scrubbing and action buttons not focused)
                    if !isScrubbing && !containerState.isActionButtonsFocused {
                        containerState.handleArrowPressBegan(
                            direction: .backward,
                            skipAmount: jumpBackwardInterval.rawValue
                        )
                    }

                case (.leftArrow, .ended), (.leftArrow, .cancelled):
                    // Skip backward press ended
                    if containerState.isScrubbing(direction: .backward) {
                        containerState.handleArrowPressEnded()
                    }

                case (.rightArrow, .began):
                    // Skip forward press began (only when not scrubbing and action buttons not focused)
                    if !isScrubbing && !containerState.isActionButtonsFocused {
                        containerState.handleArrowPressBegan(
                            direction: .forward,
                            skipAmount: jumpForwardInterval.rawValue
                        )
                    }

                case (.rightArrow, .ended), (.rightArrow, .cancelled):
                    // Skip forward press ended
                    if containerState.isScrubbing(direction: .forward) {
                        containerState.handleArrowPressEnded()
                    }

                case (.menu, _):
                    if isPresentingSupplement {
                        containerState.selectedSupplement = nil
                    } else if isPresentingOverlay {
                        // First menu press hides overlay
                        withAnimation(.linear(duration: 0.25)) {
                            containerState.isPresentingOverlay = false
                        }
                    } else {
                        // Overlay hidden - exit playback
                        manager.proxy?.stop()
                        router.dismiss()
                    }

                default:
                    // Other buttons show overlay
                    if !containerState.isPresentingOverlay {
                        withAnimation(.linear(duration: 0.25)) {
                            containerState.isPresentingOverlay = true
                        }
                    } else {
                        containerState.timer.poke()
                    }
                }
            }
        }
    }
}
