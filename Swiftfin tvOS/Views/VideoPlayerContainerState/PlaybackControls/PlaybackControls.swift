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

        // Double-tap detection for 5-minute skip
        @State
        private var lastSkipDirection: SkipDirection? = nil
        @State
        private var lastSkipTime: Date = .distantPast
        @State
        private var skipIndicatorText: String? = nil

        private enum SkipDirection {
            case forward
            case backward
        }

        private let doubleTapThreshold: TimeInterval = 0.5
        private let longSkipDuration: Duration = .seconds(300) // 5 minutes

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
                            .focusSection()
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
            if let text = skipIndicatorText {
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
                        .animation(.easeOut(duration: 0.2), value: skipIndicatorText)

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
            .onChange(of: isPresentingOverlay) { _, isPresenting in
                if isPresenting {
                    // Focus action buttons when overlay appears
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        focusGuide.transition(to: "actionButtons")
                    }
                }
            }
            .onReceive(onPressEvent) { press in
                switch press {
                case (.playPause, _):
                    // Show overlay and toggle play/pause
                    if !containerState.isPresentingOverlay {
                        withAnimation(.linear(duration: 0.25)) {
                            containerState.isPresentingOverlay = true
                        }
                    } else {
                        containerState.timer.poke()
                    }
                    manager.togglePlayPause()

                case (.leftArrow, _):
                    // Skip backward (only when not scrubbing)
                    if !isScrubbing {
                        let now = Date()
                        if lastSkipDirection == .backward,
                           now.timeIntervalSince(lastSkipTime) < doubleTapThreshold
                        {
                            // Double-tap: skip 5 minutes
                            manager.proxy?.jumpBackward(longSkipDuration)
                            skipIndicatorText = "−5:00"
                            lastSkipDirection = nil
                        } else {
                            // Single tap: skip configured interval
                            manager.proxy?.jumpBackward(jumpBackwardInterval.rawValue)
                            lastSkipDirection = .backward
                        }
                        lastSkipTime = now
                        // Auto-hide indicator after delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            skipIndicatorText = nil
                        }
                    }

                case (.rightArrow, _):
                    // Skip forward (only when not scrubbing)
                    if !isScrubbing {
                        let now = Date()
                        if lastSkipDirection == .forward,
                           now.timeIntervalSince(lastSkipTime) < doubleTapThreshold
                        {
                            // Double-tap: skip 5 minutes
                            manager.proxy?.jumpForward(longSkipDuration)
                            skipIndicatorText = "+5:00"
                            lastSkipDirection = nil
                        } else {
                            // Single tap: skip configured interval
                            manager.proxy?.jumpForward(jumpForwardInterval.rawValue)
                            lastSkipDirection = .forward
                        }
                        lastSkipTime = now
                        // Auto-hide indicator after delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            skipIndicatorText = nil
                        }
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
